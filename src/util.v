module util

import os
import crypto.md5
import crypto.sha256

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
