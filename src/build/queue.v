module build

import models { Target }
import cron.expression { CronExpression, parse_expression }
import time
import datatypes { MinHeap }
import util

struct BuildJob {
pub:
	// Next timestamp from which point this job is allowed to be executed
	timestamp time.Time
	// Required for calculating next timestamp after having pop'ed a job
	ce CronExpression
	// Actual build config sent to the agent
	config BuildConfig
}

// Allows BuildJob structs to be sorted according to their timestamp in
// MinHeaps
fn (r1 BuildJob) < (r2 BuildJob) bool {
	return r1.timestamp < r2.timestamp
}

pub struct BuildJobQueue {
	// Schedule to use for targets without explicitely defined cron expression
	default_schedule CronExpression
	// Base image to use for targets without defined base image
	default_base_image string
mut:
	mutex shared util.Dummy
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

// insert a new target's job into the queue for the given architecture. This
// job will then be endlessly rescheduled after being pop'ed, unless removed
// explicitely.
pub fn (mut q BuildJobQueue) insert(target Target, arch string) ! {
	lock q.mutex {
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
			ce: ce
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

		dump(job)
		q.queues[arch].insert(job)
	}
}

// reschedule the given job by calculating the next timestamp and re-adding it
// to its respective queue. This function is called by the pop functions
// *after* having pop'ed the job.
fn (mut q BuildJobQueue) reschedule(job BuildJob, arch string) ! {
	new_timestamp := job.ce.next_from_now()!

	new_job := BuildJob{
		...job
		timestamp: new_timestamp
	}

	q.queues[arch].insert(new_job)
}

// peek shows the first job for the given architecture that's ready to be
// executed, if present.
pub fn (q &BuildJobQueue) peek(arch string) ?BuildJob {
	rlock q.mutex {
		if arch !in q.queues {
			return none
		}

		job := q.queues[arch].peek() or { return none }

		if job.timestamp < time.now() {
			return job
		}
	}

	return none
}

// pop removes the first job for the given architecture that's ready to be
// executed from the queue and returns it, if present.
pub fn (mut q BuildJobQueue) pop(arch string) ?BuildJob {
	lock q.mutex {
		if arch !in q.queues {
			return none
		}

		mut job := q.queues[arch].peek() or { return none }

		if job.timestamp < time.now() {
			job = q.queues[arch].pop()?

			// TODO how do we handle this properly? Is it even possible for a
			// cron expression to not return a next time if it's already been
			// used before?
			q.reschedule(job, arch) or {}

			return job
		}
	}

	return none
}

// pop_n tries to pop at most n available jobs for the given architecture.
pub fn (mut q BuildJobQueue) pop_n(arch string, n int) []BuildJob {
	lock q.mutex {
		if arch !in q.queues {
			return []
		}

		mut out := []BuildJob{}

		for out.len < n {
			mut job := q.queues[arch].peek() or { break }

			if job.timestamp < time.now() {
				job = q.queues[arch].pop() or { break }

				// TODO idem
				q.reschedule(job, arch) or {}

				out << job
			} else {
				break
			}
		}

		return out
	}

	return []
}
