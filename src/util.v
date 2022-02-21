module util

import os
import io
import crypto.md5
import crypto.sha256

const reader_buf_size = 1_000_000

[noreturn]
pub fn exit_with_message(code int, msg string) {
	eprintln(msg)
	exit(code)
}

pub fn reader_to_file(mut reader io.BufferedReader, length int, path string) ? {
	mut file := os.create(path) ?
	defer {
		file.close()
	}

	mut buf := []byte{len: util.reader_buf_size}
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

// hash_file returns the md5 & sha256 hash of a given file
// TODO actually implement sha256
pub fn hash_file(path &string) ?(string, string) {
	file := os.open(path) or { return error('Failed to open file.') }

	mut md5sum := md5.new()
	mut sha256sum := sha256.new()

	buf_size := int(1_000_000)
	mut buf := []byte{len: buf_size}
	mut bytes_left := os.file_size(path)

	for bytes_left > 0 {
		// TODO check if just breaking here is safe
		bytes_read := file.read(mut buf) or { return error('Failed to read from file.') }
		bytes_left -= u64(bytes_read)

		// For now we'll assume that this always works
		md5sum.write(buf[..bytes_read]) or {
			return error('Failed to update md5 checksum. This should never happen.')
		}
		sha256sum.write(buf[..bytes_read]) or {
			return error('Failed to update sha256 checksum. This should never happen.')
		}
	}

	return md5sum.checksum().hex(), sha256sum.checksum().hex()
}
