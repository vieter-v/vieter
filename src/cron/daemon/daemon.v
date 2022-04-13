module daemon

import git
import time
import log
import datatypes { MinHeap }
import cron.expression { CronExpression, parse_expression }

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
	address              string
	api_key              string
	base_image           string
	global_schedule      CronExpression
	api_update_frequency int
	// Repos currently loaded from API.
	repos_map map[string]git.GitRepo
	// At what point to update the list of repositories.
	api_update_timestamp time.Time
	queue                MinHeap<ScheduledBuild>
	// Which builds are currently running
	builds []git.GitRepo
	// Atomic variables used to detect when a build has finished; length is the
	// same as builds
	atomics []u64
	logger  shared log.Log
}

pub fn init_daemon(logger log.Log, address string, api_key string, base_image string, global_schedule CronExpression, max_concurrent_builds int, api_update_frequency int) ?Daemon {
	mut d := Daemon{
		address: address
		api_key: api_key
		base_image: base_image
		global_schedule: global_schedule
		api_update_frequency: api_update_frequency
		atomics: []u64{len: max_concurrent_builds}
		builds: []git.GitRepo{len: max_concurrent_builds}
		logger: logger
	}

	// Initialize the repos & queue
	d.renew_repos() ?
	d.renew_queue() ?

	return d
}

pub fn (mut d Daemon) run() ? {
	println(d.queue)
	println('i am running')
}

fn (mut d Daemon) renew_repos() ? {
	mut new_repos := git.get_repos(d.address, d.api_key) ?

	d.repos_map = new_repos.move()

	d.api_update_timestamp = time.now().add_seconds(60 * d.api_update_frequency)
}

// renew_queue replaces the old queue with a new one that reflects the newest
// values in repos_map.
fn (mut d Daemon) renew_queue() ? {
	mut new_queue := MinHeap<ScheduledBuild>{}

	// Move any jobs that should have already started from the old queue onto
	// the new one
	now := time.now()

	for d.queue.len() > 0 && d.queue.peek() ?.timestamp < now {
		new_queue.insert(d.queue.pop() ?)
	}

	eprintln('hey')
	eprintln(d.repos_map)
	// For each repository in repos_map, parse their cron expression (or use
	// the default one if not present) & add them to the queue
	for id, repo in d.repos_map {
		eprintln('hey')
		ce := parse_expression(repo.schedule) or { d.global_schedule }
		// A repo that can't be scheduled will just be skipped for now
		timestamp := ce.next(now) or { continue }

		new_queue.insert(ScheduledBuild{
			repo_id: id
			repo: repo
			timestamp: timestamp
		})
	}

	d.queue = new_queue
}
