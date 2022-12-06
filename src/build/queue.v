module build

import models { Target }
import cron.expression { CronExpression, parse_expression }
import time
import datatypes { MinHeap }

struct BuildJob {
pub:
	// Earliest point this
	timestamp time.Time
	config    BuildConfig
}

// Overloaded operator for comparing ScheduledBuild objects
fn (r1 BuildJob) < (r2 BuildJob) bool {
	return r1.timestamp < r2.timestamp
}

pub struct BuildJobQueue {
	// Schedule to use for targets without explicitely defined cron expression
	default_schedule CronExpression
	// Base image to use for targets without defined base image
	default_base_image string
mut:
	// For each architecture, a priority queue is tracked
	queues map[string]MinHeap<BuildJob>
	// Each queued build job is also stored in a map, with the keys being the
	// target IDs. This is used when removing or editing targets.
	// jobs map[int]BuildJob
}

pub fn new_job_queue(default_schedule CronExpression, default_base_image string) BuildJobQueue {
	return BuildJobQueue{
		default_schedule: default_schedule
		default_base_image: default_base_image
	}
}

// insert a new job into the queue for a given target on an architecture.
pub fn (mut q BuildJobQueue) insert(target Target, arch string) ! {
	if arch !in q.queues {
		q.queues[arch] = MinHeap<BuildJob>{}
	}

	ce := if target.schedule != '' {
		parse_expression(target.schedule) or {
			return error("Error while parsing cron expression '$target.schedule' (id $target.id): $err.msg()")
		}
	} else {
		q.default_schedule
	}

	timestamp := ce.next_from_now()!

	job := BuildJob{
		timestamp: timestamp
		config: BuildConfig{
			target_id: target.id
			kind: target.kind
			url: target.url
			branch: target.branch
			repo: target.repo
			// TODO make this configurable
			base_image: q.default_base_image
		}
	}

	q.queues[arch].insert(job)
}
