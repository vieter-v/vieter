module docker

import net.unix
import io
import net.http
import strings
import net.urllib
import json
import util

const (
	socket               = '/var/run/docker.sock'
	buf_len              = 10 * 1024
	http_separator       = [u8(`\r`), `\n`, `\r`, `\n`]
	http_chunk_separator = [u8(`\r`), `\n`]
)

pub struct DockerDaemon {
mut:
	socket &unix.StreamConn
	reader &io.BufferedReader
}

pub fn new_conn() ?&DockerDaemon {
	s := unix.connect_stream(docker.socket)?

	d := &DockerDaemon{
		socket: s
		reader: io.new_buffered_reader(reader: s)
	}

	return d
}

pub fn (mut d DockerDaemon) send_request(method string, url urllib.URL) ? {
	req := '$method $url.request_uri() HTTP/1.1\nHost: localhost\n\n'

	d.socket.write_string(req)?
}

pub fn (mut d DockerDaemon) send_request_with_body(method string, url urllib.URL, content_type string, body string) ? {
	req := '$method $url.request_uri() HTTP/1.1\nHost: localhost\nContent-Type: $content_type\nContent-Length: $body.len\n\n$body\n\n'

	d.socket.write_string(req)?
}

pub fn (mut d DockerDaemon) send_request_with_json<T>(method string, url urllib.URL, data &T) ? {
	body := json.encode(data)

	return d.send_request_with_body(method, url, 'application/json', body)
}

// read_response_head consumes the socket's contents until it encounters
// '\r\n\r\n', after which it parses the response as an HTTP response.
// Importantly, this function never consumes past the HTTP separator, so the
// body can be read fully later on.
pub fn (mut d DockerDaemon) read_response_head() ?http.Response {
	mut c := 0
	mut buf := []u8{len: 4}
	mut res := []u8{}

	for {
		c = d.reader.read(mut buf)?
		res << buf[..c]

		match_len := util.match_array_in_array(buf[..c], docker.http_separator)
		// mut i := 0
		// mut match_len := 0

		// for i + match_len < c {
		//	if buf[i + match_len] == docker.http_separator[match_len] {
		//		match_len += 1
		//	} else {
		//		i += match_len + 1
		//		match_len = 0
		//	}
		//}

		if match_len == 4 {
			break
		} else if match_len > 0 {
			mut buf2 := []u8{len: 4 - match_len}
			c2 := d.reader.read(mut buf2)?
			res << buf2[..c2]

			if buf2 == docker.http_separator[match_len..] {
				break
			}
		}
	}

	return http.parse_response(res.bytestr())
}

pub fn (mut d DockerDaemon) read_response_body(length int) ?string {
	if length == 0 {
		return ''
	}

	mut buf := []u8{len: docker.buf_len}
	mut c := 0
	mut builder := strings.new_builder(docker.buf_len)

	for builder.len < length {
		c = d.reader.read(mut buf) or { break }

		builder.write(buf[..c])?
	}

	return builder.str()
}

pub fn (mut d DockerDaemon) read_response() ?(http.Response, string) {
	head := d.read_response_head()?
	content_length := head.header.get(http.CommonHeader.content_length)?.int()
	res := d.read_response_body(content_length)?

	return head, res
}

pub fn (mut d DockerDaemon) get_chunked_response_reader() &ChunkedResponseReader {
	r := new_chunked_response_reader(d.reader)

	return r
}
