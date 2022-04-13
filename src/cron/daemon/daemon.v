module daemon

import git
import time
import log
import datatypes

struct ScheduledBuild {
	repo      git.GitRepo
	timestamp time.Time
}

fn (r1 ScheduledBuild) < (r2 ScheduledBuild) bool {
	return r1.timestamp < r2.timestamp
}

pub struct Daemon {
mut:
	conf Config
	// Repos currently loaded from API.
	repos_map map[string]git.GitRepo
	// At what point to update the list of repositories.
	api_update_timestamp time.Time
	queue datatypes.MinHeap<ScheduledBuild>
	// Which builds are currently running
	builds []git.GitRepo
	// Atomic variables used to detect when a build has finished; length is the
	// same as builds
	atomics []u64
	logger shared log.Log
}

// init 
pub fn init(conf Config) Daemon {
	return Daemon{
		conf: conf
		atomics: [conf.max_concurrent_builds]u64{}
	}
}

fn (mut d Daemon) run() ? {
	d.renew_repos() ?
	d.renew_queue() ?
}

fn (mut d Daemon) renew_repos() ? {
	mut new_repos := git.get_repos(d.conf.address, d.conf.api_key) ?

	d.repos_map = new_repos.move()
}

fn (mut d Daemon) renew_queue() ? {

}
