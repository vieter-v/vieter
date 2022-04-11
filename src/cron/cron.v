module cron

import git
import datatypes
import time

struct ScheduledBuild {
	repo      git.GitRepo
	timestamp time.Time
}

fn (r1 ScheduledBuild) < (r2 ScheduledBuild) bool {
	return r1.timestamp < r2.timestamp
}

pub fn cron(conf Config) ? {
	// mut queue := datatypes.MinHeap<ScheduledBuild>{}
	// repos_map := git.get_repos(conf.address, conf.api_key) ?

	// for _, repo in repos_map {
	// 	scheduled := ScheduledBuild{
	// 		repo: repo
	// 		timestamp: 25
	// 	}

	// 	queue.insert(scheduled)
	// }

	// println(queue)
	// exp := '10/2 5 *'
	// println(parse_expression(exp) ?)
	ce := parse_expression('0 3 */2') ?
	println(ce)
	// ce := CronExpression{
	// 	minutes: [0]
	// 	hours: [3]
	// 	days: [1, 2, 3, 4, 5, 6]
	// 	months: [1, 2]
	// }
	mut t := time.Time{
		year: 2022
		month: 12
		minute: 9
		hour: 13
		day: 12
	}

	// mut t := time.now()
	println(t)

	for _ in 1..25 {
		t = ce.next(t) ?
		println(t)
	}
}
