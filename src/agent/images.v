module agent

import time
import docker
import build

struct ImageManager {
mut:
	refresh_frequency int
	images            map[string][]string  [required]
	timestamps        map[string]time.Time [required]
}

fn new_image_manager(refresh_frequency int) ImageManager {
	return ImageManager{
		refresh_frequency: refresh_frequency
		images: map[string][]string{}
		timestamps: map[string]time.Time{}
	}
}

fn (mut m ImageManager) refresh_image(base_image string) ! {
	// No need to refresh the image if the previous one is still new enough
	if base_image in m.timestamps
		&& m.timestamps[base_image].add_seconds(m.refresh_frequency) > time.now() {
		return
	}

	// TODO use better image tags for built images
	new_image := build.create_build_image(base_image) or {
		return error('Failed to build builder image from base image $base_image')
	}

	m.images[base_image] << new_image
	m.timestamps[base_image] = time.now()
}

// clean_old_images tries to remove any old but still present builder images.
fn (mut m ImageManager) clean_old_images() {
	mut dd := docker.new_conn() or { return }

	defer {
		dd.close() or {}
	}

	mut i := 0

	for image in m.images.keys() {
		i = 0

		for i < m.images[image].len - 1 {
			// For each builder image, we try to remove it by calling the Docker
			// API. If the function returns an error or false, that means the image
			// wasn't deleted. Therefore, we move the index over. If the function
			// returns true, the array's length has decreased by one so we don't
			// move the index.
			dd.remove_image(m.images[image][i]) or { i += 1 }
		}
	}
}
