module main

import docker

fn build() {
	println(docker.pull('nginx', 'latest') or { panic('yeetus') })
	// println(docker.containers() or { panic('heet') })
}
