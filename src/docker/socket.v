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

// new_conn creates a new connection to the Docker daemon.
pub fn new_conn() ?&DockerDaemon {
	s := unix.connect_stream(docker.socket)?

	d := &DockerDaemon{
		socket: s
		reader: io.new_buffered_reader(reader: s)
	}

	return d
}

// send_request sends an HTTP request without body.
pub fn (mut d DockerDaemon) send_request(method string, url urllib.URL) ? {
	req := '$method $url.request_uri() HTTP/1.1\nHost: localhost\n\n'

	d.socket.write_string(req)?

	// When starting a new request, the reader needs to be reset.
	d.reader = io.new_buffered_reader(reader: d.socket)
}

// send_request_with_body sends an HTTP request with the given body.
pub fn (mut d DockerDaemon) send_request_with_body(method string, url urllib.URL, content_type string, body string) ? {
	req := '$method $url.request_uri() HTTP/1.1\nHost: localhost\nContent-Type: $content_type\nContent-Length: $body.len\n\n$body\n\n'

	d.socket.write_string(req)?

	// When starting a new request, the reader needs to be reset.
	d.reader = io.new_buffered_reader(reader: d.socket)
}

// send_request_with_json<T> is a convenience wrapper around
// send_request_with_body that encodes the input as JSON.
pub fn (mut d DockerDaemon) send_request_with_json<T>(method string, url urllib.URL, data &T) ? {
	body := json.encode(data)

	return d.send_request_with_body(method, url, 'application/json', body)
}

// read_response_head consumes the socket's contents until it encounters
// '\r\n\r\n', after which it parses the response as an HTTP response.
// Importantly, this function never consumes the reader past the HTTP
// separator, so the body can be read fully later on.
pub fn (mut d DockerDaemon) read_response_head() ?http.Response {
	mut c := 0
	mut buf := []u8{len: 4}
	mut res := []u8{}

	for {
		c = d.reader.read(mut buf)?
		res << buf[..c]

		match_len := util.match_array_in_array(buf[..c], docker.http_separator)

		if match_len == 4 {
			break
		}

		if match_len > 0 {
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

// read_response_body reads `length` bytes from the stream. It can be used when
// the response encoding isn't chunked to fully read it.
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

// read_response is a convenience function which always consumes the entire
// response & returns it. It should only be used when we're certain that the
// result isn't too large.
pub fn (mut d DockerDaemon) read_response() ?(http.Response, string) {
	head := d.read_response_head()?

	if head.header.get(http.CommonHeader.transfer_encoding) or { '' } == 'chunked' {
		mut builder := strings.new_builder(1024)
		mut body := d.get_chunked_response_reader()

		util.reader_to_writer(mut body, mut builder) ?

		return head, builder.str()
	}

	content_length := head.header.get(http.CommonHeader.content_length)?.int()
	res := d.read_response_body(content_length)?

	return head, res
}

// get_chunked_response_reader returns a ChunkedResponseReader using the socket
// as reader.
pub fn (mut d DockerDaemon) get_chunked_response_reader() &ChunkedResponseReader {
	r := new_chunked_response_reader(d.reader)

	return r
}

// get_stream_format_reader returns a StreamFormatReader using the socket as
// reader.
pub fn (mut d DockerDaemon) get_stream_format_reader() &StreamFormatReader {
	r := new_chunked_response_reader(d.reader)
	r2 := new_stream_format_reader(r)

	return r2
}
