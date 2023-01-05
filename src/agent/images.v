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

// up_to_date returns true if the last known builder image exists and is up to
// date. If this function returns true, the last builder image may be used to
// perform a build.
pub fn (mut m ImageManager) up_to_date(base_image string) bool {
	if base_image !in m.timestamps
		|| m.timestamps[base_image].add_seconds(m.max_image_age) <= time.now() {
		return false
	}

	// It's possible the image has been removed by some external event, so we
	// check whether it actually exists as well.
	mut dd := docker.new_conn() or { return false }

	defer {
		dd.close() or {}
	}

	dd.image_inspect(m.images[base_image].last()) or {
		// Image doesn't exist, so we stop tracking it
		if err.code() == 404 {
			m.images[base_image].delete_last()
			m.timestamps.delete(base_image)
		}

		// If the inspect fails, it's either because the image doesn't exist or
		// because of some other error. Either way, we can't know *for certain*
		// that the image exists, so we return false.
		return false
	}

	return true
}

// refresh_image builds a new builder image from the given base image. This
// function should only be called if `up_to_date` returned false.
fn (mut m ImageManager) refresh_image(base_image string) ! {
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
			dd.image_remove(m.images[image][i]) or {
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
