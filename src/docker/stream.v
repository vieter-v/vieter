module docker

import io
import util
import encoding.binary
import encoding.hex

// ChunkedResponseReader parses an underlying HTTP chunked response, exposing
// it as if it was a continuous stream of data.
struct ChunkedResponseReader {
mut:
	reader              io.Reader
	bytes_left_in_chunk u64
	end_of_stream       bool
	started             bool
}

// new_chunked_response_reader creates a new ChunkedResponseReader on the heap
// with the provided reader.
pub fn new_chunked_response_reader(reader io.Reader) &ChunkedResponseReader {
	r := &ChunkedResponseReader{
		reader: reader
	}

	return r
}

// read satisfies the io.Reader interface.
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

	// Make sure we don't read more than we can safely read. This is to avoid
	// the underlying reader from becoming out of sync with our parsing:
	if buf.len > r.bytes_left_in_chunk {
		c = r.reader.read(mut buf[..r.bytes_left_in_chunk])?
	} else {
		c = r.reader.read(mut buf)?
	}

	r.bytes_left_in_chunk -= u64(c)

	return c
}

// read_chunk_size advances the reader & reads the size of the next HTTP chunk.
// This function should only be called if the previous chunk has been
// completely consumed.
fn (mut r ChunkedResponseReader) read_chunk_size() ?u64 {
	if r.started {
		mut buf := []u8{len: 2}

		// Each chunk ends with a `\r\n` which we want to skip first
		r.reader.read(mut buf)?
	}

	r.started = true

	mut res := []u8{}
	util.read_until_separator(mut r.reader, mut res, http_chunk_separator)?

	// The length of the next chunk is provided as a hexadecimal
	mut num_data := hex.decode(res#[..-2].bytestr())?

	for num_data.len < 8 {
		num_data.insert(0, 0)
	}

	num := binary.big_endian_u64(num_data)

	// This only occurs for the very last chunk, which always reports a size of
	// 0.
	if num == 0 {
		r.end_of_stream = true
	}

	return num
}

// StreamFormatReader parses an underlying stream of Docker logs, removing the
// header bytes.
struct StreamFormatReader {
mut:
	reader              io.Reader
	bytes_left_in_chunk u32
	end_of_stream       bool
}

// new_stream_format_reader creates a new StreamFormatReader using the given
// reader.
pub fn new_stream_format_reader(reader io.Reader) &StreamFormatReader {
	r := &StreamFormatReader{
		reader: reader
	}

	return r
}

// read satisfies the io.Reader interface.
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

// read_chunk_size advances the reader & reads the header bytes for the length
// of the next chunk.
fn (mut r StreamFormatReader) read_chunk_size() ?u32 {
	mut buf := []u8{len: 8}

	r.reader.read(mut buf)?

	num := binary.big_endian_u32(buf[4..])

	return num
}
