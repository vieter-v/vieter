module docker

import net.unix
import net.urllib
import net.http
import json

const socket = '/var/run/docker.sock'

const buf_len = 1024

fn send(req &string) ?http.Response {
	// Open a connection to the socket
	mut s := unix.connect_stream(docker.socket) ?

	defer {
		// This or is required because otherwise, the V compiler segfaults for
		// some reason
		// https://github.com/vlang/v/issues/13534
		s.close() or {}
	}

	// Write the request to the socket
	s.write_string(req) ?


	s.wait_for_write() ?

	mut c := 0
	mut buf := []byte{len: docker.buf_len}
	mut res := []byte{}

	for {
		c = s.read(mut buf) or { return error('Failed to read data from socket.') }
		res << buf[..c]

		if c < docker.buf_len {
			break
		}
	}

	// If the response isn't a chunked reply, we return early
	parsed := http.parse_response(res.bytestr()) ?

	if parsed.header.get(http.CommonHeader.transfer_encoding) or { '' } != 'chunked' {
		return parsed
	}

	// We loop until we've encountered the end of the chunked response
	for res.len < 5 || res#[-5..] != [byte(`0`), `\r`, `\n`, `\r`, `\n`] {
		// Wait for the server to respond
		s.wait_for_write() ?

		for {
			c = s.read(mut buf) or { return error('Failed to read data from socket.') }
			res << buf[..c]

			if c < docker.buf_len {
				break
			}
		}
	}

	// Decode chunked response
	return http.parse_response(res.bytestr())

}

fn request_with_body(method string, url urllib.URL, body &string) ?http.Response {
	req := '$method $url.request_uri() HTTP/1.1\nHost: localhost\nContent-Length: ${body.len}\n$body\n'

	return send(req)
}

fn request(method string, url urllib.URL) ?http.Response {
	req := '$method $url.request_uri() HTTP/1.1\nHost: localhost\n\n'

	return send(req)
}

pub fn request_with_json<T>(method string, url urllib.URL, data T) ?http.Response {
	body := json.encode(data)
	println(body)

	return request_with_body(method, url, body)
}

fn get(url urllib.URL) ?http.Response {
	return request('GET', url)
}

struct ImagePull {
	from_image string [json: fromImage]
	tag string
}

pub fn pull(image string, tag string) ?http.Response {
	// data := ImagePull{
	// 	from_image: image
	// 	tag: tag
	// }

	// return request_with_json("POST", urllib.parse("/images/create") ?, data)
	return request("POST", urllib.parse("/images/create?fromImage=$image&tag=$tag") ?)
}
