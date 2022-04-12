module cron

import git
import datatypes
import time
import rand

struct ScheduledBuild {
	repo      git.GitRepo
	timestamp time.Time
}

fn (r1 ScheduledBuild) < (r2 ScheduledBuild) bool {
	return r1.timestamp < r2.timestamp
}

pub fn cron(conf Config) ? {
	mut queue := datatypes.MinHeap<time.Time>{}

	ce := parse_expression('0 3') ?
	t := time.parse('2002-01-01 00:00:00') ?

	println(t)
	t2 := ce.next(t) ?
	println(t2)
}
