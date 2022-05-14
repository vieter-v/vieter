module util

import os
import io
import crypto.md5
import crypto.sha256

const reader_buf_size = 1_000_000

const prefixes = ['B', 'KB', 'MB', 'GB']

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

// reader_to_writer tries to consume the entire reader & write it to the writer.
pub fn reader_to_writer(mut reader io.Reader, mut writer io.Writer) ? {
	mut buf := []u8{len: 10 * 1024}

	for {
		c := reader.read(mut buf) or { break }

		writer.write(buf) or { break }
	}
}

// reader_to_file writes the contents of a BufferedReader to a file
pub fn reader_to_file(mut reader io.BufferedReader, length int, path string) ? {
	mut file := os.create(path)?
	defer {
		file.close()
	}

	mut buf := []u8{len: util.reader_buf_size}
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
			// file.flush()

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
	mut buf := []u8{len: buf_size}
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

// match_array_in_array<T> returns how many elements of a2 overlap with a1. For
// example, if a1 = "abcd" & a2 = "cd", the result will be 2. If the match is
// not at the end of a1, the result is 0.
pub fn match_array_in_array<T>(a1 []T, a2 []T) int {
	mut i := 0
	mut match_len := 0

	for i + match_len < a1.len {
		if a1[i + match_len] == a2[match_len] {
			match_len += 1
		} else {
			i += match_len + 1
			match_len = 0
		}
	}

	return match_len
}
