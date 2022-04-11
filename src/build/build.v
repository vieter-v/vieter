module build

import docker
import encoding.base64
import time
import git
import os

const container_build_dir = '/build'

const build_image_repo = 'vieter-build'

fn create_build_image(base_image string) ?string {
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
	docker.pull_image(image_name, image_tag) ?

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

fn build(conf Config) ? {
	build_arch := os.uname().machine

	// We get the repos map from the Vieter instance
	repos_map := git.get_repos(conf.address, conf.api_key) ?

	// We filter out any repos that aren't allowed to be built on this
	// architecture
	filtered_repos := repos_map.keys().map(repos_map[it]).filter(it.arch.contains(build_arch))

	// No point in doing work if there's no repos present
	if filtered_repos.len == 0 {
		return
	}

	// First, we create a base image which has updated repos n stuff
	image_id := create_build_image(conf.base_image) ?

	for repo in filtered_repos {
		// TODO what to do with PKGBUILDs that build multiple packages?
		commands := [
			'git clone --single-branch --depth 1 --branch $repo.branch $repo.url repo',
			'cd repo',
			'makepkg --nobuild --nodeps',
			'source PKGBUILD',
			// The build container checks whether the package is already
			// present on the server
			'curl --head --fail $conf.address/$repo.repo/$build_arch/\$pkgname-\$pkgver-\$pkgrel && exit 0',
			'MAKEFLAGS="-j\$(nproc)" makepkg -s --noconfirm --needed && for pkg in \$(ls -1 *.pkg*); do curl -XPOST -T "\$pkg" -H "X-API-KEY: \$API_KEY" $conf.address/$repo.repo/publish; done',
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
