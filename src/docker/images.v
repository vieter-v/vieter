module docker

import net.http
import net.urllib
import json

struct Image {
pub:
	id string [json: Id]
}

// pull_image pulls the given image:tag.
pub fn (mut d DockerDaemon) pull_image(image string, tag string) ? {
	d.send_request('POST', urllib.parse('/v1.41/images/create?fromImage=$image&tag=$tag')?)?
	head := d.read_response_head()?

	if head.status_code != 200 {
		content_length := head.header.get(http.CommonHeader.content_length)?.int()
		body := d.read_response_body(content_length)?
		data := json.decode(DockerError, body)?

		return error(data.message)
	}

	// Keep reading the body until the pull has completed
	mut body := d.get_chunked_response_reader()

	mut buf := []u8{len: 1024}

	for {
		body.read(mut buf) or { break }
	}
}

// create_image_from_container creates a new image from a container.
pub fn (mut d DockerDaemon) create_image_from_container(id string, repo string, tag string) ?Image {
	d.send_request('POST', urllib.parse('/v1.41/commit?container=$id&repo=$repo&tag=$tag')?)?
	head, body := d.read_response()?

	if head.status_code != 201 {
		data := json.decode(DockerError, body)?

		return error(data.message)
	}

	data := json.decode(Image, body)?

	return data
}

// remove_image removes the image with the given id.
pub fn (mut d DockerDaemon) remove_image(id string) ? {
	d.send_request('DELETE', urllib.parse('/v1.41/images/$id')?)?
	head, body := d.read_response()?

	if head.status_code != 200 {
		data := json.decode(DockerError, body)?

		return error(data.message)
	}
}
