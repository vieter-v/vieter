module daemon

import git
import time
import log
import datatypes { MinHeap }
import cron.expression { CronExpression, parse_expression }
import math
import build

struct ScheduledBuild {
pub:
	repo_id   string
	repo      git.GitRepo
	timestamp time.Time
}

fn (r1 ScheduledBuild) < (r2 ScheduledBuild) bool {
	return r1.timestamp < r2.timestamp
}

pub struct Daemon {
mut:
	address                 string
	api_key                 string
	base_image              string
	builder_image           string
	global_schedule         CronExpression
	api_update_frequency    int
	image_rebuild_frequency int
	// Repos currently loaded from API.
	repos_map map[string]git.GitRepo
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
	d.renew_repos() ?
	d.renew_queue() ?
	d.rebuild_base_image() ?

	return d
}

// run starts the actual daemon process. It runs builds when possible &
// periodically refreshes the list of repositories to ensure we stay in sync.
pub fn (mut d Daemon) run() ? {
	for {
		finished_builds := d.clean_finished_builds() ?

		// Update the API's contents if needed & renew the queue
		if time.now() >= d.api_update_timestamp {
			d.renew_repos() ?
			d.renew_queue() ?
		}
		// The finished builds should only be rescheduled if the API contents
		// haven't been renewed.
		else {
			for sb in finished_builds {
				d.schedule_build(sb.repo_id, sb.repo) ?
			}
		}

		// TODO remove old builder images.
		// This issue is less trivial than it sounds, because a build could
		// still be running when the image has to be rebuilt. That would
		// prevent the image from being removed. Therefore, we will need to
		// keep track of a list or something & remove an image once we have
		// made sure it isn't being used anymore.
		if time.now() >= d.image_build_timestamp {
			d.rebuild_base_image() ?
		}

		// Schedules new builds when possible
		d.start_new_builds() ?

		// If there are builds currently running, the daemon should refresh
		// every second to clean up any finished builds & start new ones.
		mut delay := time.Duration(1 * time.second)

		// Sleep either until we have to refresh the repos or when the next
		// build has to start, with a minimum of 1 second.
		if d.current_build_count() == 0 {
			now := time.now()
			delay = d.api_update_timestamp - now

			if d.queue.len() > 0 {
				time_until_next_job := d.queue.peek() ?.timestamp - now

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
fn (mut d Daemon) schedule_build(repo_id string, repo git.GitRepo) ? {
	ce := parse_expression(repo.schedule) or {
		// TODO This shouldn't return an error if the expression is empty.
		d.lerror("Error while parsing cron expression '$repo.schedule' ($repo_id): $err.msg()")

		d.global_schedule
	}
	// A repo that can't be scheduled will just be skipped for now
	timestamp := ce.next_from_now() ?

	d.queue.insert(ScheduledBuild{
		repo_id: repo_id
		repo: repo
		timestamp: timestamp
	})
}

fn (mut d Daemon) renew_repos() ? {
	d.ldebug('Renewing repos...')
	mut new_repos := git.get_repos(d.address, d.api_key) ?

	d.repos_map = new_repos.move()

	d.api_update_timestamp = time.now().add_seconds(60 * d.api_update_frequency)
}

// renew_queue replaces the old queue with a new one that reflects the newest
// values in repos_map.
fn (mut d Daemon) renew_queue() ? {
	d.ldebug('Renewing queue...')
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
		if d.queue.peek() ?.timestamp < now {
			new_queue.insert(d.queue.pop() ?)
		} else {
			break
		}
	}

	d.queue = new_queue

	// For each repository in repos_map, parse their cron expression (or use
	// the default one if not present) & add them to the queue
	for id, repo in d.repos_map {
		d.schedule_build(id, repo) ?
	}
}

fn (mut d Daemon) rebuild_base_image() ? {
	d.linfo("Rebuilding builder image....")

	d.builder_image = build.create_build_image(d.base_image) ?
	d.image_build_timestamp = time.now().add_seconds(60 * d.image_rebuild_frequency)
}
