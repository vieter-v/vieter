module build

import docker
import encoding.base64
import time
import os
import strings
import util
import models { GitRepo }

const (
	container_build_dir = '/build'
	build_image_repo    = 'vieter-build'
)

// create_build_image creates a builder image given some base image which can
// then be used to build & package Arch images. It mostly just updates the
// system, install some necessary packages & creates a non-root user to run
// makepkg with. The base image should be some Linux distribution that uses
// Pacman as its package manager.
pub fn create_build_image(base_image string) ?string {
	mut dd := docker.new_conn()?

	defer {
		dd.close() or {}
	}

	commands := [
		// Update repos & install required packages
		'pacman -Syu --needed --noconfirm base-devel git'
		// Add a non-root user to run makepkg
		'groupadd -g 1000 builder',
		'useradd -mg builder builder'
		// Make sure they can use sudo without a password
		"echo 'builder ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers"
		// Create the directory for the builds & make it writeable for the
		// build user
		'mkdir /build',
		'chown -R builder:builder /build',
	]
	cmds_str := base64.encode_str(commands.join('\n'))

	c := docker.NewContainer{
		image: base_image
		env: ['BUILD_SCRIPT=$cmds_str']
		entrypoint: ['/bin/sh', '-c']
		cmd: ['echo \$BUILD_SCRIPT | base64 -d | /bin/sh -e']
	}

	// This check is needed so the user can pass "archlinux" without passing a
	// tag & make it still work
	image_parts := base_image.split_nth(':', 2)
	image_name := image_parts[0]
	image_tag := if image_parts.len > 1 { image_parts[1] } else { 'latest' }

	// We pull the provided image
	dd.pull_image(image_name, image_tag)?

	id := dd.create_container(c)?.id
	// id := docker.create_container(c)?
	dd.start_container(id)?

	// This loop waits until the container has stopped, so we can remove it after
	for {
		data := dd.inspect_container(id)?

		if !data.state.running {
			break
		}

		time.sleep(1 * time.second)
	}

	// Finally, we create the image from the container
	// As the tag, we use the epoch value
	// TODO also add the base image's name into the image name to prevent
	// conflicts.
	tag := time.sys_mono_now().str()
	image := dd.create_image_from_container(id, 'vieter-build', tag)?
	dd.remove_container(id)?

	return image.id
}

pub struct BuildResult {
pub:
	start_time time.Time
	end_time   time.Time
	exit_code  int
	logs       string
}

// build_repo builds, packages & publishes a given Arch package based on the
// provided GitRepo. The base image ID should be of an image previously created
// by create_build_image. It returns the logs of the container.
pub fn build_repo(address string, api_key string, base_image_id string, repo &GitRepo) ?BuildResult {
	mut dd := docker.new_conn()?

	defer {
		dd.close() or {}
	}

	build_arch := os.uname().machine
	build_script := create_build_script(address, repo, build_arch)

	// We convert the build script into a base64 string, which then gets passed
	// to the container as an env var
	base64_script := base64.encode_str(build_script)

	c := docker.NewContainer{
		image: '$base_image_id'
		env: ['BUILD_SCRIPT=$base64_script', 'API_KEY=$api_key']
		entrypoint: ['/bin/sh', '-c']
		cmd: ['echo \$BUILD_SCRIPT | base64 -d | /bin/bash -e']
		work_dir: '/build'
		user: '0:0'
	}

	id := dd.create_container(c)?.id
	dd.start_container(id)?

	mut data := dd.inspect_container(id)?

	// This loop waits until the container has stopped, so we can remove it after
	for data.state.running {
		time.sleep(1 * time.second)

		data = dd.inspect_container(id)?
	}

	mut logs_stream := dd.get_container_logs(id)?

	// Read in the entire stream
	mut logs_builder := strings.new_builder(10 * 1024)
	util.reader_to_writer(mut logs_stream, mut logs_builder)?

	dd.remove_container(id)?

	return BuildResult{
		start_time: data.state.start_time
		end_time: data.state.end_time
		exit_code: data.state.exit_code
		logs: logs_builder.str()
	}
}
