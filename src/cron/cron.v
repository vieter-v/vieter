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
	exp := '10/2 5 *'
	println(parse_expression(exp) ?)
}
