module main

import docker

fn build() {
    println(docker.pull('archlinux', 'latest') or { panic('yeetus') })
	// println(docker.containers() or { panic('heet') })
}
