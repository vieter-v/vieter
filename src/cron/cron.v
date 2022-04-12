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

	for _ in 0..5000 {
		minute := rand.int_in_range(0, 60) ?
		hour := rand.int_in_range(0, 23) ?
		ce := parse_expression('$minute $hour') ?

		t := ce.next_from_now() ?
		// println(t)
		queue.insert(t)
	}

	for queue.len() > 0 {
		println(queue.pop() ?)
	}
}
