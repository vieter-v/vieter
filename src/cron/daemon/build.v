module daemon

import time
import sync.stdatomic

const build_empty = 0
const build_running = 1
const build_done = 2

// reschedule_builds looks for any builds with status code 2 & re-adds them to
// the queue.
fn (mut d Daemon) reschedule_builds() ? {
	for i in 0..d.atomics.len {
		if stdatomic.load_u64(&d.atomics[i]) == build_done {
			stdatomic.store_u64(&d.atomics[i], build_empty)
			sb := d.builds[i]

			d.schedule_build(sb.repo_id, sb.repo) ?
		}
	}
}

// update_builds starts as many builds as possible.
fn (mut d Daemon) update_builds() ? {
	now := time.now()

	for d.queue.len() > 0 {
		if d.queue.peek() ?.timestamp < now {
			sb := d.queue.pop() ?

			// If this build couldn't be scheduled, no more will be possible.
			if !d.start_build(sb)? {
				break
			}
		} else {
			break
		}
	}
}

// start_build starts a build for the given ScheduledBuild object.
fn (mut d Daemon) start_build(sb ScheduledBuild) ?bool {
	for i in 0..d.atomics.len {
		if stdatomic.load_u64(&d.atomics[i]) == build_empty {
			stdatomic.store_u64(&d.atomics[i], build_running)
			d.builds[i] = sb

			go d.run_build(i, sb)

			return true
		}
	}

	return false
}

// run_build actually starts the build process for a given repo.
fn (mut d Daemon) run_build(build_index int, sb ScheduledBuild) ? {
	time.sleep(10 * time.second)

	stdatomic.store_u64(&d.atomics[build_index], build_done)
}

