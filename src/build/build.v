module build

import docker
import encoding.base64
import time
import json
import server
import env
import net.http
import cli
import git

const container_build_dir = '/build'

const build_image_repo = 'vieter-build'

fn create_build_image() ?string {
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
		image: 'archlinux:latest'
		env: ['BUILD_SCRIPT=$cmds_str']
		entrypoint: ['/bin/sh', '-c']
		cmd: ['echo \$BUILD_SCRIPT | base64 -d | /bin/sh -e']
	}

	// First, we pull the latest archlinux image
	docker.pull_image('archlinux', 'latest') ?

	id := docker.create_container(c) ?
	docker.start_container(id) ?

	// This loop waits until the container has stopped, so we can remove it after
	for {
		data := docker.inspect_container(id) ?

		if !data.state.running {
			break
		}

		// Wait for 5 seconds
		time.sleep(5000000000)
	}

	// Finally, we create the image from the container
	// As the tag, we use the epoch value
	tag := time.sys_mono_now().str()
	image := docker.create_image_from_container(id, 'vieter-build', tag) ?
	docker.remove_container(id) ?

	return image.id
}

fn build(conf env.BuildConfig) ? {
	// We get the repos list from the Vieter instance
	mut req := http.new_request(http.Method.get, '$conf.address/api/repos', '') ?
	req.add_custom_header('X-Api-Key', conf.api_key) ?

	res := req.do() ?
	repos := json.decode([]git.GitRepo, res.text) ?

	// No point in doing work if there's no repos present
	if repos.len == 0 {
		return
	}

	// First, we create a base image which has updated repos n stuff
	image_id := create_build_image() ?

	for repo in repos {
		// TODO what to do with PKGBUILDs that build multiple packages?
		commands := [
			'git clone --single-branch --depth 1 --branch $repo.branch $repo.url repo',
			'cd repo',
			'makepkg --nobuild --nodeps',
			'source PKGBUILD',
			// The build container checks whether the package is already present on the server
			'curl --head --fail $conf.address/\$pkgname-\$pkgver-\$pkgrel-\$(uname -m).pkg.tar.zst && exit 0',
			'MAKEFLAGS="-j\$(nproc)" makepkg -s --noconfirm --needed && for pkg in \$(ls -1 *.pkg*); do curl -XPOST -T "\$pkg" -H "X-API-KEY: \$API_KEY" $conf.address/publish; done',
		]

		// We convert the list of commands into a base64 string, which then gets
		// passed to the container as an env var
		cmds_str := base64.encode_str(commands.join('\n'))

		c := docker.NewContainer{
			image: '$image_id'
			env: ['BUILD_SCRIPT=$cmds_str', 'API_KEY=$conf.api_key']
			entrypoint: ['/bin/sh', '-c']
			cmd: ['echo \$BUILD_SCRIPT | base64 -d | /bin/bash -e']
			work_dir: '/build'
			user: 'builder:builder'
		}

		id := docker.create_container(c) ?
		docker.start_container(id) ?

		// This loop waits until the container has stopped, so we can remove it after
		for {
			data := docker.inspect_container(id) ?

			if !data.state.running {
				break
			}

			// Wait for 5 seconds
			time.sleep(5000000000)
		}

		docker.remove_container(id) ?
	}

	// Finally, we remove the builder image
	docker.remove_image(image_id) ?
}
