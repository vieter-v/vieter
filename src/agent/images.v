module agent

import time
import docker

struct ImageManager {
	images map[string]string
	timestamps map[string]time.Time
}

// clean_old_base_images tries to remove any old but still present builder
// images.
fn (mut d AgentDaemon) clean_old_base_images() {
	mut i := 0

	mut dd := docker.new_conn() or {
		d.lerror('Failed to connect to Docker socket.')
		return
	}

	defer {
		dd.close() or {}
	}

	for i < d.builder_images.len - 1 {
		// For each builder image, we try to remove it by calling the Docker
		// API. If the function returns an error or false, that means the image
		// wasn't deleted. Therefore, we move the index over. If the function
		// returns true, the array's length has decreased by one so we don't
		// move the index.
		dd.remove_image(d.builder_images[i]) or { i += 1 }
	}
}

// rebuild_base_image builds a builder image from the given base image.
/* fn (mut d AgentDaemon) build_base_image(base_image string) bool { */
/* 	d.linfo('Rebuilding builder image....') */

/* 	d.builder_images << build.create_build_image(d.base_image) or { */
/* 		d.lerror('Failed to rebuild base image. Retrying in ${daemon.rebuild_base_image_retry_timout}s...') */
/* 		d.image_build_timestamp = time.now().add_seconds(daemon.rebuild_base_image_retry_timout) */

/* 		return false */
/* 	} */

/* 	d.image_build_timestamp = time.now().add_seconds(60 * d.image_rebuild_frequency) */

/* 	return true */
/* } */
