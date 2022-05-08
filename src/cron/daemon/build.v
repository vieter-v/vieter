module daemon

import time
import sync.stdatomic
import build
import os

const (
	build_empty   = 0
	build_running = 1
	build_done    = 2
)

// clean_finished_builds removes finished builds from the build slots & returns
// them.
fn (mut d Daemon) clean_finished_builds() []ScheduledBuild {
	mut out := []ScheduledBuild{}

	for i in 0 .. d.atomics.len {
		if stdatomic.load_u64(&d.atomics[i]) == daemon.build_done {
			stdatomic.store_u64(&d.atomics[i], daemon.build_empty)
			out << d.builds[i]
		}
	}

	return out
}

// update_builds starts as many builds as possible.
fn (mut d Daemon) start_new_builds() {
	now := time.now()

	for d.queue.len() > 0 {
		elem := d.queue.peek() or {
			d.lerror("queue.peek() unexpectedly returned an error. This shouldn't happen.")

			break
		}

		if elem.timestamp < now {
			sb := d.queue.pop() or {
				d.lerror("queue.pop() unexpectedly returned an error. This shouldn't happen.")

				break
			}

			// If this build couldn't be scheduled, no more will be possible.
			if !d.start_build(sb) {
				d.queue.insert(sb)
				break
			}
		} else {
			break
		}
	}
}

// start_build starts a build for the given ScheduledBuild object.
fn (mut d Daemon) start_build(sb ScheduledBuild) bool {
	for i in 0 .. d.atomics.len {
		if stdatomic.load_u64(&d.atomics[i]) == daemon.build_empty {
			stdatomic.store_u64(&d.atomics[i], daemon.build_running)
			d.builds[i] = sb

			go d.run_build(i, sb)

			return true
		}
	}

	return false
}

// run_build actually starts the build process for a given repo.
fn (mut d Daemon) run_build(build_index int, sb ScheduledBuild) {
	d.linfo('started build: $sb.repo.url $sb.repo.branch')

	// 0 means success, 1 means failure
	mut status := 0

	res := build.build_repo(d.client.address, d.client.api_key, d.builder_images.last(),
		&sb.repo) or {
		d.ldebug('build_repo error: $err.msg()')
		status = 1

		build.BuildResult{}
	}

	if status == 0 {
		d.linfo('finished build: $sb.repo.url $sb.repo.branch; uploading logs...')

		build_arch := os.uname().machine
		d.client.add_build_log(sb.repo.id, res.start_time, res.end_time, build_arch, res.exit_code,
			res.logs) or { d.lerror('Failed to upload logs for $sb.repo.url $sb.repo.arch') }
	} else {
		d.linfo('failed build: $sb.repo.url $sb.repo.branch')
	}

	stdatomic.store_u64(&d.atomics[build_index], daemon.build_done)
}

// current_build_count returns how many builds are currently running.
fn (mut d Daemon) current_build_count() int {
	mut res := 0

	for i in 0 .. d.atomics.len {
		if stdatomic.load_u64(&d.atomics[i]) == daemon.build_running {
			res += 1
		}
	}

	return res
}
