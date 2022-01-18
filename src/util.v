module util

import os
import crypto.md5
import crypto.sha256

// hash_file returns the md5 & sha256 hash of a given file
pub fn hash_file(path &string) ?(string, string) {
	file := os.open(path) or { return error('Failed to open file.') }

	mut md5sum := md5.new()
	mut sha256sum := sha256.new()

	buf_size := i32(1_000_000)
	mut buf := []byte{len: buf_size}
	mut bytes_left := os.file_size(path)

	for bytes_left > 0 {
		// TODO check if just breaking here is safe
		bytes_read := file.read(mut buf) or { break }
		bytes_left -= u64(bytes_read)

		if bytes_left > buf_size {
			md5sum.write(buf)
			sha256sum.write(buf)
		}
	}

	return md5sum.sum(buf).hex(), sha256sum.sum(buf).hex()
}
