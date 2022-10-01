module util

import os
import crypto.sha256

const (
	reader_buf_size = 1_000_000
	prefixes        = ['B', 'KB', 'MB', 'GB']
)

// Dummy struct to work around the fact that you can only share structs, maps &
// arrays
pub struct Dummy {
	x int
}

// exit_with_message exits the program with a given status code after having
// first printed a specific message to STDERR
[noreturn]
pub fn exit_with_message(code int, msg string) {
	eprintln(msg)
	exit(code)
}

// hash_file returns the sha256 hash of a given file
pub fn hash_file(path &string) ?string {
	file := os.open(path) or { return error('Failed to open file.') }

	mut sha256sum := sha256.new()

	buf_size := int(1_000_000)
	mut buf := []u8{len: buf_size}
	mut bytes_left := os.file_size(path)

	for bytes_left > 0 {
		// TODO check if just breaking here is safe
		bytes_read := file.read(mut buf) or { return error('Failed to read from file.') }
		bytes_left -= u64(bytes_read)

		// This function never actually fails, but returns an option to follow
		// the Writer interface.
		sha256sum.write(buf[..bytes_read])?
	}

	return sha256sum.checksum().hex()
}

// pretty_bytes converts a byte count to human-readable version
pub fn pretty_bytes(bytes int) string {
	mut i := 0
	mut n := f32(bytes)

	for n >= 1024 {
		i++
		n /= 1024
	}

	return '${n:.2}${util.prefixes[i]}'
}
