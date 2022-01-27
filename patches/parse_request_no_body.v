// Parse the header of a raw HTTP request into a Request object
pub fn parse_request_head(mut reader io.BufferedReader) ?Request {
	// request line
	mut line := reader.read_line() ?
	method, target, version := parse_request_line(line) ?

	// headers
	mut header := new_header()
	line = reader.read_line() ?
	for line != '' {
		key, value := parse_header(line) ?
		header.add_custom(key, value) ?
		line = reader.read_line() ?
	}
	header.coerce(canonicalize: true)

	return Request{
		method: method
		url: target.str()
		header: header
		version: version
	}
}
