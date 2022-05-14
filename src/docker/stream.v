module docker

import io
import util
import encoding.binary
import encoding.hex

struct ChunkedResponseReader {
mut:
	reader              io.Reader
	bytes_left_in_chunk u64
	end_of_stream       bool
	started             bool
}

pub fn new_chunked_response_reader(reader io.Reader) &ChunkedResponseReader {
	r := &ChunkedResponseReader{
		reader: reader
	}

	return r
}

// We satisfy the io.Reader interface
pub fn (mut r ChunkedResponseReader) read(mut buf []u8) ?int {
	if r.end_of_stream {
		return none
	}

	if r.bytes_left_in_chunk == 0 {
		r.bytes_left_in_chunk = r.read_chunk_size()?

		if r.end_of_stream {
			return none
		}
	}

	mut c := 0

	if buf.len > r.bytes_left_in_chunk {
		c = r.reader.read(mut buf[..r.bytes_left_in_chunk])?
	} else {
		c = r.reader.read(mut buf)?
	}

	r.bytes_left_in_chunk -= u64(c)

	return c
}

fn (mut r ChunkedResponseReader) read_chunk_size() ?u64 {
	mut buf := []u8{len: 2}
	mut res := []u8{}

	if r.started {
		// Each chunk ends with a `\r\n` which we want to skip first
		r.reader.read(mut buf)?
	}

	r.started = true

	for {
		c := r.reader.read(mut buf)?
		res << buf[..c]

		match_len := util.match_array_in_array(buf[..c], http_chunk_separator)

		if match_len == http_chunk_separator.len {
			break
		}

		if match_len > 0 {
			mut buf2 := []u8{len: 2 - match_len}
			c2 := r.reader.read(mut buf2)?
			res << buf2[..c2]

			if buf2 == http_chunk_separator[match_len..] {
				break
			}
		}
	}

	mut num_data := hex.decode(res#[..-2].bytestr())?

	for num_data.len < 8 {
		num_data.insert(0, 0)
	}

	num := binary.big_endian_u64(num_data)

	if num == 0 {
		r.end_of_stream = true
	}

	return num
}

struct StreamFormatReader {
	stdout bool
	stderr bool
	stdin  bool
mut:
	reader              io.Reader
	bytes_left_in_chunk u32
	end_of_stream       bool
}

pub fn new_stream_format_reader(reader io.Reader) &StreamFormatReader {
	r := &StreamFormatReader{
		reader: reader
	}

	return r
}

pub fn (mut r StreamFormatReader) read(mut buf []u8) ?int {
	if r.end_of_stream {
		return none
	}

	if r.bytes_left_in_chunk == 0 {
		r.bytes_left_in_chunk = r.read_chunk_size()?

		if r.end_of_stream {
			return none
		}
	}

	mut c := 0

	if buf.len > r.bytes_left_in_chunk {
		c = r.reader.read(mut buf[..r.bytes_left_in_chunk])?
	} else {
		c = r.reader.read(mut buf)?
	}

	r.bytes_left_in_chunk -= u32(c)

	return c
}

fn (mut r StreamFormatReader) read_chunk_size() ?u32 {
	mut buf := []u8{len: 8}

	r.reader.read(mut buf)?

	num := binary.big_endian_u32(buf[4..])

	return num
}
