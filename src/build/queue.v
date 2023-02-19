module build

import models { BuildConfig, Target }
import cron
import time
import datatypes { MinHeap }
import util

struct BuildJob {
pub mut:
	// Time at which this build job was created/queued
	created time.Time
	// Next timestamp from which point this job is allowed to be executed
	timestamp time.Time
	// Required for calculating next timestamp after having pop'ed a job
	ce &cron.Expression = unsafe { nil }
	// Actual build config sent to the agent
	config BuildConfig
	// Whether this is a one-time job
	single bool
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
	default_schedule &cron.Expression
	// Base image to use for targets without defined base image
	default_base_image string
mut:
	mutex shared util.Dummy
	// For each architecture, a priority queue is tracked
	queues map[string]MinHeap[BuildJob]
	// When a target is removed from the server or edited, its previous build
	// configs will be invalid. This map allows for those to be simply skipped
	// by ignoring any build configs created before this timestamp.
	invalidated map[int]time.Time
}

// new_job_queue initializes a new job queue
pub fn new_job_queue(default_schedule &cron.Expression, default_base_image string) BuildJobQueue {
	return BuildJobQueue{
		default_schedule: unsafe { default_schedule }
		default_base_image: default_base_image
		invalidated: map[int]time.Time{}
	}
}

// insert_all executes insert for each architecture of the given Target.
pub fn (mut q BuildJobQueue) insert_all(target Target) ! {
	for arch in target.arch {
		q.insert(target: target, arch: arch.value)!
	}
}

[params]
pub struct InsertConfig {
	target Target [required]
	arch   string [required]
	single bool
	force  bool
	now    bool
}

// insert a new target's job into the queue for the given architecture. This
// job will then be endlessly rescheduled after being pop'ed, unless removed
// explicitely.
pub fn (mut q BuildJobQueue) insert(input InsertConfig) ! {
	lock q.mutex {
		if input.arch !in q.queues {
			q.queues[input.arch] = MinHeap[BuildJob]{}
		}

		mut job := BuildJob{
			created: time.now()
			single: input.single
			config: input.target.as_build_config(q.default_base_image, input.force)
		}

		if !input.now {
			ce := if input.target.schedule != '' {
				cron.parse_expression(input.target.schedule) or {
					return error("Error while parsing cron expression '${input.target.schedule}' (id ${input.target.id}): ${err.msg()}")
				}
			} else {
				q.default_schedule
			}

			job.timestamp = ce.next_from_now()
			job.ce = ce
		} else {
			job.timestamp = time.now()
		}

		q.queues[input.arch].insert(job)
	}
}

// reschedule the given job by calculating the next timestamp and re-adding it
// to its respective queue. This function is called by the pop functions
// *after* having pop'ed the job.
fn (mut q BuildJobQueue) reschedule(job BuildJob, arch string) {
	new_timestamp := job.ce.next_from_now()

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
	// Even peek requires a write lock, because pop_invalid can modify the data
	// structure
	lock q.mutex {
		if arch !in q.queues {
			return none
		}

		q.pop_invalid(arch)
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

		q.pop_invalid(arch)
		mut job := q.queues[arch].peek() or { return none }

		if job.timestamp < time.now() {
			job = q.queues[arch].pop() or { return none }

			if !job.single {
				q.reschedule(job, arch)
			}

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

				if !job.single {
					q.reschedule(job, arch)
				}

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
