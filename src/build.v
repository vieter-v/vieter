module main

import docker
import encoding.base64
import rand

const container_build_dir = '/build'

struct GitRepo {
	url string [required]
	branch string [required]
}

fn build() {
	// println(docker.pull('nginx', 'latest') or { panic('yeetus') })
	// println(docker.containers() or { panic('heet') })
	repos := [
		GitRepo{'https://git.rustybever.be/Chewing_Bever/st', 'master'}
		GitRepo{'https://aur.archlinux.org/libxft-bgra.git', 'master'}
	]
	mut uuids := []string{}

	mut commands := [
		// Update repos & install required packages
		'pacman -Syu --needed --noconfirm base-devel git'
		// Add a non-root user to run makepkg
		'groupadd -g 1000 builder'
		'useradd -mg builder builder'
		// Make sure they can use sudo without a password
		"echo 'builder ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers"
		// Create the directory for the builds & make it writeable for the
		// build user
		'mkdir /build'
		'chown -R builder:builder /build'
		// "su builder -c 'git clone https://git.rustybever.be/Chewing_Bever/st /build/st'"
		// 'su builder -c \'cd /build/st && makepkg -s --noconfirm --needed && for pkg in \$(ls -1 *.pkg*); do curl -XPOST -T "\${pkg}" -H "X-API-KEY: \$API_KEY" https://arch.r8r.be/publish; done\''
	]

	for repo in repos {
		mut uuid := rand.uuid_v4()

		// Just to be sure we don't have any collisions
		for uuids.contains(uuid) {
			uuid = rand.uuid_v4()
		}

		uuids << uuid

		commands << "su builder -c 'git clone --single-branch --depth 1 --branch $repo.branch $repo.url /build/$uuid'"
		commands << 'su builder -c \'cd /build/$uuid && makepkg -s --noconfirm --needed && for pkg in \$(ls -1 *.pkg*); do curl -XPOST -T "\${pkg}" -H "X-API-KEY: \$API_KEY" https://arch.r8r.be/publish; done\''
	}
	println(commands)

	// We convert the list of commands into a base64 string
	cmds_str := base64.encode_str(commands.join('\n'))

	c := docker.NewContainer{
		image: 'archlinux:latest'
		env: ['BUILD_SCRIPT=$cmds_str']
		entrypoint: ['/bin/sh', '-c']
		cmd: ['echo \$BUILD_SCRIPT | base64 -d | /bin/sh -e']
	}

	id := docker.create_container(c) or { panic('aaaahh') }
	print(docker.start_container(id) or { panic('yikes') })
}
