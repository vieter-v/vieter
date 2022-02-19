module main

import docker

fn build() {
	println(docker.containers() or { panic('yeet') })
}
