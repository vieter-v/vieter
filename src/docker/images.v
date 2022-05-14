module docker

import net.http
import net.urllib
import json

struct Image {
pub:
	id string [json: Id]
}

// pull_image pulls tries to pull the image for the given image & tag
pub fn pull_image(image string, tag string) ?http.Response {
	return request('POST', urllib.parse('/v1.41/images/create?fromImage=$image&tag=$tag')?)
}

// create_image_from_container creates a new image from a container with the
// given repo & tag, given the container's ID.
pub fn create_image_from_container(id string, repo string, tag string) ?Image {
	res := request('POST', urllib.parse('/v1.41/commit?container=$id&repo=$repo&tag=$tag')?)?

	if res.status_code != 201 {
		return error('Failed to create image from container.')
	}

	return json.decode(Image, res.text) or {}
}

// remove_image removes the image with the given ID.
pub fn remove_image(id string) ?bool {
	res := request('DELETE', urllib.parse('/v1.41/images/$id')?)?

	return res.status_code == 200
}
