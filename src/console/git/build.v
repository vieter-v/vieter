module git

import client
import docker
import os
import build

// build builds every Git repo in the server's list.
fn build(conf Config, repo_id int) ? {
	c := client.new(conf.address, conf.api_key)
	repo := c.get_git_repo(repo_id)?

	build_arch := os.uname().machine

	println('Creating base image...')
	image_id := build.create_build_image(conf.base_image)?

	println('Running build...')
	res := build.build_repo(conf.address, conf.api_key, image_id, repo)?

	println('Removing build image...')

	mut dd := docker.new_conn()?

	defer {
		dd.close() or {}
	}

	dd.remove_image(image_id)?

	println('Uploading logs to Vieter...')
	c.add_build_log(repo.id, res.start_time, res.end_time, build_arch, res.exit_code,
		res.logs)?
}
