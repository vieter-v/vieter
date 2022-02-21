module main

import os
import io

[noreturn]
fn exit_with_message(code int, msg string) {
	eprintln(msg)
	exit(code)
}

fn reader_to_file(mut reader io.BufferedReader, length int, path string) ? {
	mut file := os.create(path) ?
	defer {
		file.close()
	}

	mut buf := []byte{len: buf_size}
	mut bytes_left := length

	// Repeat as long as the stream still has data
	for bytes_left > 0 {
		// TODO check if just breaking here is safe
		bytes_read := reader.read(mut buf) or { break }
		bytes_left -= bytes_read

		mut to_write := bytes_read

		for to_write > 0 {
			// TODO don't just loop infinitely here
			bytes_written := file.write(buf[bytes_read - to_write..bytes_read]) or { continue }

			to_write = to_write - bytes_written
		}
	}
}

fn main() {
	if os.args.len == 1 {
		exit_with_message(1, 'No action provided.')
	}

	match os.args[1] {
		'server' { server() ? }
		'build' { build() ? }
		else { exit_with_message(1, 'Unknown action: ${os.args[1]}') }
	}
}
