module daemon

import git
import time
import log
import datatypes { MinHeap }
import cron.expression { CronExpression, parse_expression }
import math
import build
import docker
import db

const (
	// How many seconds to wait before retrying to update API if failed
	api_update_retry_timeout        = 5
	// How many seconds to wait before retrying to rebuild image if failed
	rebuild_base_image_retry_timout = 30
)

struct ScheduledBuild {
pub:
	repo_id   string
	repo      db.GitRepo
	timestamp time.Time
}

// Overloaded operator for comparing ScheduledBuild objects
fn (r1 ScheduledBuild) < (r2 ScheduledBuild) bool {
	return r1.timestamp < r2.timestamp
}

pub struct Daemon {
mut:
	address                 string
	api_key                 string
	base_image              string
	builder_images          []string
	global_schedule         CronExpression
	api_update_frequency    int
	image_rebuild_frequency int
	// Repos currently loaded from API.
	repos []db.GitRepo
	// At what point to update the list of repositories.
	api_update_timestamp  time.Time
	image_build_timestamp time.Time
	queue                 MinHeap<ScheduledBuild>
	// Which builds are currently running
	builds []ScheduledBuild
	// Atomic variables used to detect when a build has finished; length is the
	// same as builds
	atomics []u64
	logger  shared log.Log
}

// init_daemon initializes a new Daemon object. It renews the repositories &
// populates the build queue for the first time.
pub fn init_daemon(logger log.Log, address string, api_key string, base_image string, global_schedule CronExpression, max_concurrent_builds int, api_update_frequency int, image_rebuild_frequency int) ?Daemon {
	mut d := Daemon{
		address: address
		api_key: api_key
		base_image: base_image
		global_schedule: global_schedule
		api_update_frequency: api_update_frequency
		image_rebuild_frequency: image_rebuild_frequency
		atomics: []u64{len: max_concurrent_builds}
		builds: []ScheduledBuild{len: max_concurrent_builds}
		logger: logger
	}

	// Initialize the repos & queue
	d.renew_repos()
	d.renew_queue()
	if !d.rebuild_base_image() {
		return error('The base image failed to build. The Vieter cron daemon cannot run without an initial builder image.')
	}

	return d
}

// run starts the actual daemon process. It runs builds when possible &
// periodically refreshes the list of repositories to ensure we stay in sync.
pub fn (mut d Daemon) run() {
	for {
		finished_builds := d.clean_finished_builds()

		// Update the API's contents if needed & renew the queue
		if time.now() >= d.api_update_timestamp {
			d.renew_repos()
			d.renew_queue()
		}
		// The finished builds should only be rescheduled if the API contents
		// haven't been renewed.
		else {
			for sb in finished_builds {
				d.schedule_build(sb.repo)
			}
		}

		// TODO remove old builder images.
		// This issue is less trivial than it sounds, because a build could
		// still be running when the image has to be rebuilt. That would
		// prevent the image from being removed. Therefore, we will need to
		// keep track of a list or something & remove an image once we have
		// made sure it isn't being used anymore.
		if time.now() >= d.image_build_timestamp {
			d.rebuild_base_image()
			// In theory, executing this function here allows an old builder
			// image to exist for at most image_rebuild_frequency minutes.
			d.clean_old_base_images()
		}

		// Schedules new builds when possible
		d.start_new_builds()

		// If there are builds currently running, the daemon should refresh
		// every second to clean up any finished builds & start new ones.
		mut delay := time.Duration(1 * time.second)

		// Sleep either until we have to refresh the repos or when the next
		// build has to start, with a minimum of 1 second.
		if d.current_build_count() == 0 {
			now := time.now()
			delay = d.api_update_timestamp - now

			if d.queue.len() > 0 {
				elem := d.queue.peek() or {
					d.lerror("queue.peek() unexpectedly returned an error. This shouldn't happen.")

					// This is just a fallback option. In theory, queue.peek()
					// should *never* return an error or none, because we check
					// its len beforehand.
					time.sleep(1)
					continue
				}

				time_until_next_job := elem.timestamp - now

				delay = math.min(delay, time_until_next_job)
			}
		}

		// We sleep for at least one second. This is to prevent the program
		// from looping agressively when a cronjob can be scheduled, but
		// there's no spots free for it to be started.
		delay = math.max(delay, 1 * time.second)

		d.ldebug('Sleeping for ${delay}...')

		time.sleep(delay)
	}
}

// schedule_build adds the next occurence of the given repo build to the queue.
fn (mut d Daemon) schedule_build(repo db.GitRepo) {
	ce := if repo.schedule != '' {
		parse_expression(repo.schedule) or {
			// TODO This shouldn't return an error if the expression is empty.
			d.lerror("Error while parsing cron expression '$repo.schedule' (id $repo.id): $err.msg()")

			d.global_schedule
		}
	} else {
		d.global_schedule
	}

	// A repo that can't be scheduled will just be skipped for now
	timestamp := ce.next_from_now() or {
		d.lerror("Couldn't calculate next timestamp from '$repo.schedule'; skipping")
		return
	}

	d.queue.insert(ScheduledBuild{
		repo: repo
		timestamp: timestamp
	})
}

// renew_repos requests the newest list of Git repos from the server & replaces
// the old one.
fn (mut d Daemon) renew_repos() {
	d.linfo('Renewing repos...')

	mut new_repos := git.get_repos(d.address, d.api_key) or {
		d.lerror('Failed to renew repos. Retrying in ${daemon.api_update_retry_timeout}s...')
		d.api_update_timestamp = time.now().add_seconds(daemon.api_update_retry_timeout)

		return
	}

	d.repos = new_repos

	d.api_update_timestamp = time.now().add_seconds(60 * d.api_update_frequency)
}

// renew_queue replaces the old queue with a new one that reflects the newest
// values in repos_map.
fn (mut d Daemon) renew_queue() {
	d.linfo('Renewing queue...')
	mut new_queue := MinHeap<ScheduledBuild>{}

	// Move any jobs that should have already started from the old queue onto
	// the new one
	now := time.now()

	// For some reason, using
	// ```v
	// for d.queue.len() > 0 && d.queue.peek() ?.timestamp < now {
	//```
	// here causes the function to prematurely just exit, without any errors or anything, very weird
	// https://github.com/vlang/v/issues/14042
	for d.queue.len() > 0 {
		elem := d.queue.pop() or {
			d.lerror("queue.pop() returned an error. This shouldn't happen.")
			continue
		}

		if elem.timestamp < now {
			new_queue.insert(elem)
		} else {
			break
		}
	}

	d.queue = new_queue

	// For each repository in repos_map, parse their cron expression (or use
	// the default one if not present) & add them to the queue
	for repo in d.repos {
		d.schedule_build(repo)
	}
}

// rebuild_base_image recreates the builder image.
fn (mut d Daemon) rebuild_base_image() bool {
	d.linfo('Rebuilding builder image....')

	d.builder_images << build.create_build_image(d.base_image) or {
		d.lerror('Failed to rebuild base image. Retrying in ${daemon.rebuild_base_image_retry_timout}s...')
		d.image_build_timestamp = time.now().add_seconds(daemon.rebuild_base_image_retry_timout)

		return false
	}

	d.image_build_timestamp = time.now().add_seconds(60 * d.image_rebuild_frequency)

	return true
}

// clean_old_base_images tries to remove any old but still present builder
// images.
fn (mut d Daemon) clean_old_base_images() {
	mut i := 0

	for i < d.builder_images.len - 1 {
		// For each builder image, we try to remove it by calling the Docker
		// API. If the function returns an error or false, that means the image
		// wasn't deleted. Therefore, we move the index over. If the function
		// returns true, the array's length has decreased by one so we don't
		// move the index.
		if !docker.remove_image(d.builder_images[i]) or { false } {
			i += 1
		}
	}
}
