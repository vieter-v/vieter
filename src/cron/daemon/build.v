module daemon

import git
import time
import sync.stdatomic

// update_builds starts as many builds as possible.
fn (mut d Daemon) update_builds() ? {
	now := time.now()

	for d.queue.len() > 0 {
		if d.queue.peek() ?.timestamp < now {
			sb := d.queue.pop() ?

			// If this build couldn't be scheduled, no more will be possible.
			if !d.start_build(sb.repo_id)? {
				break
			}
		} else {
			break
		}
	}
}

// start_build starts a build for the given repo_id.
fn (mut d Daemon) start_build(repo_id string) ?bool {
	for i in 0..d.atomics.len {
		if stdatomic.load_u64(&d.atomics[i]) == 0 {
			stdatomic.store_u64(&d.atomics[i], 1)

			go d.run_build(i, d.repos_map[repo_id])

			return true
		}
	}

	return false
}

fn (mut d Daemon) run_build(build_index int, repo git.GitRepo) ? {
	time.sleep(10 * time.second)

	stdatomic.store_u64(&d.atomics[build_index], 2)
}

