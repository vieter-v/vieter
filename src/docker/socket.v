module docker

import net.unix
import io
import net.http

const socket = '/var/run/docker.sock'

const buf_len = 10 * 1024

pub struct DockerDaemon {
mut:
	socket &unix.StreamConn
	reader &io.BufferedReader
}

pub fn new_conn() ?DockerDaemon {
	s := unix.connect_stream(socket) ?

	d := DockerDaemon{socket: s, reader: io.new_buffered_reader(reader: s)}

	return d
}

fn (mut d DockerDaemon) send_request(req &string) ? {
	d.socket.write_string(req) ?
	d.socket.wait_for_write() ?
}

// read_response_head consumes the socket's contents until it encounters
// '\n\n', after which it parses the response as an HTTP response.
fn (mut d DockerDaemon) read_response_head() ?http.Response {
	mut c := 0
	mut buf := [buf_len]u8{len: docker.buf_len}
	mut res := []u8{}

	for {
		c = d.socket.read(mut buf) ?
		res << buf[..c]

		if res#[-2..] == [u8(`\n`), `\n`] {
			break
		}
	}

	return http.parse_response(res.bytestr())
}
