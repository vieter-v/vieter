module docker

import net.unix
import net.urllib
import net.http
import json

// send writes a request to the Docker socket, waits for a response & returns
// it.
fn send(req &string) ?http.Response {
	// Open a connection to the socket
	mut s := unix.connect_stream(docker.socket) or {
		return error('Failed to connect to socket ${docker.socket}.')
	}

	defer {
		// This or is required because otherwise, the V compiler segfaults for
		// some reason
		// https://github.com/vlang/v/issues/13534
		s.close() or {}
	}

	// Write the request to the socket
	s.write_string(req) or { return error('Failed to write request to socket ${docker.socket}.') }

	s.wait_for_write()?

	mut c := 0
	mut buf := []u8{len: docker.buf_len}
	mut res := []u8{}

	for {
		c = s.read(mut buf) or { return error('Failed to read data from socket ${docker.socket}.') }
		res << buf[..c]

		if c < docker.buf_len {
			break
		}
	}

	// After reading the first part of the response, we parse it into an HTTP
	// response. If it isn't chunked, we return early with the data.
	parsed := http.parse_response(res.bytestr()) or {
		return error('Failed to parse HTTP response from socket ${docker.socket}.')
	}

	if parsed.header.get(http.CommonHeader.transfer_encoding) or { '' } != 'chunked' {
		return parsed
	}

	// We loop until we've encountered the end of the chunked response
	// A chunked HTTP response always ends with '0\r\n\r\n'.
	for res.len < 5 || res#[-5..] != [u8(`0`), `\r`, `\n`, `\r`, `\n`] {
		// Wait for the server to respond
		s.wait_for_write()?

		for {
			c = s.read(mut buf) or {
				return error('Failed to read data from socket ${docker.socket}.')
			}
			res << buf[..c]

			if c < docker.buf_len {
				break
			}
		}
	}

	// Decode chunked response
	return http.parse_response(res.bytestr())
}

// request_with_body sends a request to the Docker socket with the given body.
fn request_with_body(method string, url urllib.URL, content_type string, body string) ?http.Response {
	req := '$method $url.request_uri() HTTP/1.1\nHost: localhost\nContent-Type: $content_type\nContent-Length: $body.len\n\n$body\n\n'

	return send(req)
}

// request sends a request to the Docker socket with an empty body.
fn request(method string, url urllib.URL) ?http.Response {
	req := '$method $url.request_uri() HTTP/1.1\nHost: localhost\n\n'

	return send(req)
}

// request_with_json<T> sends a request to the Docker socket with a given JSON
// payload
pub fn request_with_json<T>(method string, url urllib.URL, data &T) ?http.Response {
	body := json.encode(data)

	return request_with_body(method, url, 'application/json', body)
}
