module targets

import client
import docker
import os
import build

// build locally builds the target with the given id.
fn build(conf Config, target_id int) ! {
	c := client.new(conf.address, conf.api_key)
	target := c.get_target(target_id)!

	build_arch := os.uname().machine

	println('Creating base image...')
	image_id := build.create_build_image(conf.base_image)!

	println('Running build...')
	res := build.build_target(conf.address, conf.api_key, image_id, target)!

	println('Removing build image...')

	mut dd := docker.new_conn()!

	defer {
		dd.close() or {}
	}

	dd.remove_image(image_id)!

	println('Uploading logs to Vieter...')
	c.add_build_log(target.id, res.start_time, res.end_time, build_arch, res.exit_code,
		res.logs)!
}
