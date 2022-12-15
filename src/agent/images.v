module agent

import time
import docker
import build

// An ImageManager is a utility that creates builder images from given base
// images, updating these builder images if they've become too old. This
// structure can manage images from any number of base images, paving the way
// for configurable base images per target/repository.
struct ImageManager {
	max_image_age int [required]
mut:
	// For each base image, one or more builder images can exist at the same
	// time
	images map[string][]string [required]
	// For each base image, we track when its newest image was built
	timestamps map[string]time.Time [required]
}

// new_image_manager initializes a new image manager.
fn new_image_manager(max_image_age int) ImageManager {
	return ImageManager{
		max_image_age: max_image_age
		images: map[string][]string{}
		timestamps: map[string]time.Time{}
	}
}

// get returns the name of the newest image for the given base image. Note that
// this function should only be called *after* a first call to `refresh_image`.
pub fn (m &ImageManager) get(base_image string) string {
	return m.images[base_image].last()
}

// refresh_image builds a new builder image from the given base image if the
// previous builder image is too old or non-existent. This function will do
// nothing if these conditions aren't met, so it's safe to call it every time
// you want to ensure an image is up to date.
fn (mut m ImageManager) refresh_image(base_image string) ! {
	if base_image in m.timestamps
		&& m.timestamps[base_image].add_seconds(m.max_image_age) > time.now() {
		return
	}

	// TODO use better image tags for built images
	new_image := build.create_build_image(base_image) or {
		return error('Failed to build builder image from base image $base_image')
	}

	m.images[base_image] << new_image
	m.timestamps[base_image] = time.now()
}

// clean_old_images removes all older builder images that are no longer in use.
// The function will always leave at least one builder image, namely the newest
// one.
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
			dd.remove_image(m.images[image][i]) or {
				// The image was removed by an external event
				if err.code() == 404 {
					m.images[image].delete(i)
				}
				// The image couldn't be removed, so we need to keep track of
				// it
				else {
					i += 1
				}

				continue
			}

			m.images[image].delete(i)
		}
	}
}
