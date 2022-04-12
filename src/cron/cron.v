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
	ce := parse_expression('0 3') ?
	t := time.parse('2002-01-01 00:00:00') ?
	t2 := ce.next(t) ?
	println(t2)
}
