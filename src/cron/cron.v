module cron

import git
import time

struct ScheduledBuild {
	repo      git.GitRepo
	timestamp time.Time
}

fn (r1 ScheduledBuild) < (r2 ScheduledBuild) bool {
	return r1.timestamp < r2.timestamp
}

// cron starts a cron daemon & starts periodically scheduling builds.
pub fn cron(conf Config) ? {
	println('WIP')
}
