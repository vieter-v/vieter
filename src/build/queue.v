module build

import models { Target }
import cron.expression { CronExpression, parse_expression }
import time
import datatypes { MinHeap }
import util

struct BuildJob {
pub:
	// Time at which this build job was created/queued
	created time.Time
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

// The build job queue is responsible for managing the list of scheduled builds
// for each architecture. Agents receive jobs from this queue.
pub struct BuildJobQueue {
	// Schedule to use for targets without explicitely defined cron expression
	default_schedule CronExpression
	// Base image to use for targets without defined base image
	default_base_image string
mut:
	mutex shared util.Dummy
	// For each architecture, a priority queue is tracked
	queues map[string]MinHeap<BuildJob>
	// When a target is removed from the server or edited, its previous build
	// configs will be invalid. This map allows for those to be simply skipped
	// by ignoring any build configs created before this timestamp.
	invalidated map[int]time.Time
}

// new_job_queue initializes a new job queue
pub fn new_job_queue(default_schedule CronExpression, default_base_image string) BuildJobQueue {
	return BuildJobQueue{
		default_schedule: default_schedule
		default_base_image: default_base_image
		invalidated: map[int]time.Time{}
	}
}

// insert_all executes insert for each architecture of the given Target.
pub fn (mut q BuildJobQueue) insert_all(target Target) ! {
	for arch in target.arch {
		q.insert(target, arch.value)!
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
			created: time.now()
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
		created: time.now()
		timestamp: new_timestamp
	}

	q.queues[arch].insert(new_job)
}

// pop_invalid pops all invalid jobs.
fn (mut q BuildJobQueue) pop_invalid(arch string) {
	for {
		job := q.queues[arch].peek() or { return }

		if job.config.target_id in q.invalidated
			&& job.created < q.invalidated[job.config.target_id] {
			// This pop *should* never fail according to the source code
			q.queues[arch].pop() or {}
		} else {
			break
		}
	}
}

// peek shows the first job for the given architecture that's ready to be
// executed, if present.
pub fn (mut q BuildJobQueue) peek(arch string) ?BuildJob {
	rlock q.mutex {
		if arch !in q.queues {
			return none
		}

		q.pop_invalid(arch)
		job := q.queues[arch].peek()?

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

		q.pop_invalid(arch)
		mut job := q.queues[arch].peek()?

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
			q.pop_invalid(arch)
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

// invalidate a target's old build jobs.
pub fn (mut q BuildJobQueue) invalidate(target_id int) {
	q.invalidated[target_id] = time.now()
}
