module agent

import log
import sync.stdatomic
import build
import models { BuildConfig }
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
	client client.Client
mut:
	images ImageManager
	// Which builds are currently running; length is conf.max_concurrent_builds
	builds []BuildConfig
	// Atomic variables used to detect when a build has finished; length is
	// conf.max_concurrent_builds
	atomics []u64
}

// agent_init initializes a new agent
fn agent_init(logger log.Log, conf Config) AgentDaemon {
	mut d := AgentDaemon{
		logger: logger
		client: client.new(conf.address, conf.api_key)
		conf: conf
		images: new_image_manager(conf.image_rebuild_frequency * 60)
		builds: []BuildConfig{len: conf.max_concurrent_builds}
		atomics: []u64{len: conf.max_concurrent_builds}
	}

	return d
}

// run starts the actual agent daemon. This function will run forever.
pub fn (mut d AgentDaemon) run() {
	// This is just so that the very first time the loop is ran, the jobs are
	// always polled
	mut last_poll_time := time.now().add_seconds(-d.conf.polling_frequency)
	mut sleep_time := 0 * time.second
	mut finished, mut empty, mut running := 0, 0, 0

	for {
		if sleep_time > 0 {
			d.ldebug('Sleeping for $sleep_time')
			time.sleep(sleep_time)
		}

		finished, empty = d.update_atomics()
		running = d.conf.max_concurrent_builds - finished - empty

		// No new finished builds and no free slots, so there's nothing to be
		// done
		if finished + empty == 0 {
			sleep_time = 1 * time.second
			continue
		}

		// Builds have finished, so old builder images might have freed up.
		// TODO this might query the docker daemon too frequently.
		if finished > 0 {
			d.images.clean_old_images()
		}

		// The agent will always poll for new jobs after at most
		// `polling_frequency` seconds. However, when jobs have finished, the
		// agent will also poll for new jobs. This is because jobs are often
		// clustered together (especially when mostly using the global cron
		// schedule), so there's a much higher chance jobs are available.
		if finished > 0 || time.now() >= last_poll_time.add_seconds(d.conf.polling_frequency) {
			d.ldebug('Polling for new jobs')

			new_configs := d.client.poll_jobs(d.conf.arch, finished + empty) or {
				d.lerror('Failed to poll jobs: $err.msg()')

				// TODO pick a better delay here
				sleep_time = 5 * time.second
				continue
			}

			d.ldebug('Received $new_configs.len jobs')

			last_poll_time = time.now()

			for config in new_configs {
				// Make sure a recent build base image is available for
				// building the config
				if !d.images.up_to_date(config.base_image) {
					d.linfo('Building builder image from base image $config.base_image')

					// TODO handle this better than to just skip the config
					d.images.refresh_image(config.base_image) or {
						d.lerror(err.msg())
						continue
					}
				}

				// It's technically still possible that the build image is
				// removed in the very short period between building the
				// builder image and starting a build container with it. If
				// this happens, faith really just didn't want you to do this
				// build.

				d.start_build(config)
				running++
			}
		}

		// The agent is not doing anything, so we just wait until the next poll
		// time
		if running == 0 {
			sleep_time = last_poll_time.add_seconds(d.conf.polling_frequency) - time.now()
		} else {
			sleep_time = 1 * time.second
		}
	}
}

// update_atomics checks for each build whether it's completed, and sets it to
// empty again if so. The return value is a tuple `(finished, empty)` where
// `finished` is how many builds were just finished and thus set to empty, and
// `empty` is how many build slots were already empty. The amount of running
// builds can then be calculated by substracting these two values from the
// total allowed concurrent builds.
fn (mut d AgentDaemon) update_atomics() (int, int) {
	mut finished := 0
	mut empty := 0

	for i in 0 .. d.atomics.len {
		if stdatomic.load_u64(&d.atomics[i]) == agent.build_done {
			stdatomic.store_u64(&d.atomics[i], agent.build_empty)
			finished++
		} else if stdatomic.load_u64(&d.atomics[i]) == agent.build_empty {
			empty++
		}
	}

	return finished, empty
}

// start_build starts a build for the given BuildConfig.
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
	d.linfo('started build: $config')

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
		d.linfo('Uploading build logs for $config')

		// TODO use the arch value here
		build_arch := os.uname().machine
		d.client.add_build_log(config.target_id, res.start_time, res.end_time, build_arch,
			res.exit_code, res.logs) or { d.lerror('Failed to upload logs for $config') }
	} else {
		d.lwarn('an error occurred during build: $config')
	}

	stdatomic.store_u64(&d.atomics[build_index], agent.build_done)
}
