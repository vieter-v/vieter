module agent

import log
import sync.stdatomic
import build { BuildConfig }
import client
import time
import os

const (
	build_empty   = 0
	build_running = 1
	build_done    = 2
)

struct AgentDaemon {
	logger shared log.Log
	conf   Config
mut:
	images ImageManager
	// Which builds are currently running; length is same as
	// conf.max_concurrent_builds
	builds []BuildConfig
	// Atomic variables used to detect when a build has finished; length is the
	// same as conf.max_concurrent_builds
	client  client.Client
	atomics []u64
}

fn agent_init(logger log.Log, conf Config) AgentDaemon {
	mut d := AgentDaemon{
		logger: logger
		client: client.new(conf.address, conf.api_key)
		conf: conf
		images: new_image_manager(conf.image_rebuild_frequency)
		builds: []BuildConfig{len: conf.max_concurrent_builds}
		atomics: []u64{len: conf.max_concurrent_builds}
	}

	return d
}

pub fn (mut d AgentDaemon) run() {
	// This is just so that the very first time the loop is ran, the jobs are
	// always polled
	mut last_poll_time := time.now().add_seconds(-d.conf.polling_frequency)

	for {
		free_builds := d.update_atomics()

		// All build slots are taken, so there's nothing to be done
		if free_builds == 0 {
			time.sleep(1 * time.second)
			continue
		}

		// Builds have finished, so old builder images might have freed up.
		d.images.clean_old_images()

		// Poll for new jobs
		if time.now() >= last_poll_time.add_seconds(d.conf.polling_frequency) {
			new_configs := d.client.poll_jobs(d.conf.arch, free_builds) or {
				d.lerror('Failed to poll jobs: $err.msg()')

				time.sleep(5 * time.second)
				continue
			}
			last_poll_time = time.now()

			// Schedule new jobs
			for config in new_configs {
				// TODO handle this better than to just skip the config
				// Make sure a recent build base image is available for building the config
				d.images.refresh_image(config.base_image) or {
					d.lerror(err.msg())
					continue
				}
				d.start_build(config)
			}

			time.sleep(1 * time.second)
		}
		// Builds are running, so check again after one second
		else if free_builds < d.conf.max_concurrent_builds {
			time.sleep(1 * time.second)
		}
		// The agent is not doing anything, so we just wait until the next poll
		// time
		else {
			time_until_next_poll := time.now() - last_poll_time
			time.sleep(time_until_next_poll)
		}
	}
}

// update_atomics checks for each build whether it's completed, and sets it to
// free again if so. The return value is how many build slots are currently
// free.
fn (mut d AgentDaemon) update_atomics() int {
	mut count := 0

	for i in 0 .. d.atomics.len {
		if stdatomic.load_u64(&d.atomics[i]) == agent.build_done {
			stdatomic.store_u64(&d.atomics[i], agent.build_empty)
			count++
		} else if stdatomic.load_u64(&d.atomics[i]) == agent.build_empty {
			count++
		}
	}

	return count
}

// start_build starts a build for the given BuildConfig object.
fn (mut d AgentDaemon) start_build(config BuildConfig) bool {
	for i in 0 .. d.atomics.len {
		if stdatomic.load_u64(&d.atomics[i]) == agent.build_empty {
			stdatomic.store_u64(&d.atomics[i], agent.build_running)
			d.builds[i] = config

			go d.run_build(i, config)

			return true
		}
	}

	return false
}

// run_build actually starts the build process for a given target.
fn (mut d AgentDaemon) run_build(build_index int, config BuildConfig) {
	d.linfo('started build: $config.url -> $config.repo')

	// 0 means success, 1 means failure
	mut status := 0

	new_config := BuildConfig{
		...config
		base_image: d.images.get(config.base_image)
	}

	res := build.build_config(d.client.address, d.client.api_key, new_config) or {
		d.ldebug('build_config error: $err.msg()')
		status = 1

		build.BuildResult{}
	}

	if status == 0 {
		d.linfo('finished build: $config.url -> $config.repo; uploading logs...')

		build_arch := os.uname().machine
		d.client.add_build_log(config.target_id, res.start_time, res.end_time, build_arch,
			res.exit_code, res.logs) or {
			d.lerror('Failed to upload logs for build: $config.url -> $config.repo')
		}
	} else {
		d.linfo('an error occured during build: $config.url -> $config.repo')
	}

	stdatomic.store_u64(&d.atomics[build_index], agent.build_done)
}
