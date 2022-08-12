// Copyright (c) 2019-2022 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module web

import os
import io
import net
import net.http
import net.urllib
import time
import json
import log

// The Context struct represents the Context which hold the HTTP request and response.
// It has fields for the query, form, files.
pub struct Context {
pub:
	// HTTP Request
	req http.Request
	// TODO Response
pub mut:
	// TCP connection to client.
	// But beware, do not store it for further use, after request processing web will close connection.
	conn &net.TcpConn
	// Gives access to a shared logger object
	logger shared log.Log
	// REQUEST
	// time.ticks() from start of web connection handle.
	// You can use it to determine how much time is spent on your request.
	page_gen_start    i64
	static_files      map[string]string
	static_mime_types map[string]string
	// Map containing query params for the route.
	// Example: `http://localhost:3000/index?q=vpm&order_by=desc => { 'q': 'vpm', 'order_by': 'desc' }
	query map[string]string
	// Multipart-form fields.
	form map[string]string
	// Files from multipart-form.
	files map[string][]http.FileData
	// Allows reading the request body
	reader io.BufferedReader
	// RESPONSE
	status       http.Status = http.Status.ok
	content_type string      = 'text/plain'
	// response headers
	header http.Header
}

struct FileData {
pub:
	filename     string
	content_type string
	data         string
}

struct Route {
	methods []http.Method
	path    string
}

// Defining this method is optional.
// before_request is called before every request (aka middleware).
// Probably you can use it for check user session cookie or add header.
pub fn (ctx Context) before_request() {}

// send_string writes the given string to the TCP connection socket.
fn (mut ctx Context) send_string(s string) ? {
	ctx.conn.write(s.bytes())?
}

// send_reader reads at most `size` bytes from the given reader & writes them
// to the TCP connection socket. Internally, a 10KB buffer is used, to avoid
// having to store all bytes in memory at once.
fn (mut ctx Context) send_reader(mut reader io.Reader, size u64) ? {
	mut buf := []u8{len: 10_000}
	mut bytes_left := size

	// Repeat as long as the stream still has data
	for bytes_left > 0 {
		bytes_read := reader.read(mut buf)?
		bytes_left -= u64(bytes_read)

		mut to_write := bytes_read

		for to_write > 0 {
			// TODO don't just loop infinitely here
			bytes_written := ctx.conn.write(buf[bytes_read - to_write..bytes_read]) or { continue }

			to_write = to_write - bytes_written
		}
	}
}

// send_response_header constructs a valid HTTP response with an empty body &
// sends it to the client.
pub fn (mut ctx Context) send_response_header() ? {
	mut resp := http.Response{
		header: ctx.header.join(headers_close)
	}
	resp.set_version(.v1_1)
	resp.set_status(ctx.status)
	ctx.send_string(resp.bytestr())?
}

// send_response constructs the resulting HTTP response with the given body
// string & sends it to the client.
pub fn (mut ctx Context) send_response(res string) bool {
	ctx.send_response_header() or { return false }
	ctx.send_string(res) or { return false }

	return true
}

// send_reader_response constructs the resulting HTTP response with the given
// body & streams the reader's contents to the client.
pub fn (mut ctx Context) send_reader_response(mut reader io.Reader, size u64) bool {
	ctx.send_response_header() or { return false }
	ctx.send_reader(mut reader, size) or { return false }

	return true
}

// text responds to a request with some plaintext.
pub fn (mut ctx Context) text(status http.Status, s string) Result {
	ctx.status = status
	ctx.content_type = 'text/plain'
	ctx.send_response(s)

	return Result{}
}

// json<T> HTTP_OK with json_s as payload with content-type `application/json`
pub fn (mut ctx Context) json<T>(status http.Status, j T) Result {
	ctx.status = status
	ctx.content_type = 'application/json'

	json_s := json.encode(j)
	ctx.send_response(json_s)

	return Result{}
}

// file Response HTTP_OK with file as payload
// This function manually implements responses because it needs to stream the file contents
pub fn (mut ctx Context) file(f_path string) Result {
	if !os.is_file(f_path) {
		return ctx.not_found()
	}

	// ext := os.file_ext(f_path)
	// data := os.read_file(f_path) or {
	// 	eprint(err.msg())
	// 	ctx.server_error(500)
	// 	return Result{}
	// }
	// content_type := web.mime_types[ext]
	// if content_type == '' {
	// 	eprintln('no MIME type found for extension $ext')
	// 	ctx.server_error(500)

	// 	return Result{}
	// }

	// First, we return the headers for the request

	// We open the file before sending the headers in case reading fails
	file_size := os.file_size(f_path)

	mut file := os.open(f_path) or {
		eprintln(err.msg())
		ctx.server_error(500)
		return Result{}
	}

	// build header
	header := http.new_header_from_map({
		// http.CommonHeader.content_type:   content_type
		http.CommonHeader.content_length: file_size.str()
	}).join(ctx.header)

	mut resp := http.Response{
		header: header.join(headers_close)
	}
	resp.set_version(.v1_1)
	resp.set_status(ctx.status)
	ctx.send_string(resp.bytestr()) or { return Result{} }
	ctx.send_reader(mut file, file_size) or { return Result{} }

	//	mut buf := []u8{len: 1_000_000}
	//	mut bytes_left := file_size

	//	// Repeat as long as the stream still has data
	//	for bytes_left > 0 {
	//		// TODO check if just breaking here is safe
	//		bytes_read := file.read(mut buf) or { break }
	//		bytes_left -= u64(bytes_read)

	//		mut to_write := bytes_read

	//		for to_write > 0 {
	//			// TODO don't just loop infinitely here
	//			bytes_written := ctx.conn.write(buf[bytes_read - to_write..bytes_read]) or { continue }

	//			to_write = to_write - bytes_written
	//		}
	//	}

	return Result{}
}

// status responds with an empty textual response, essentially only returning
// the given status code.
pub fn (mut ctx Context) status(status http.Status) Result {
	return ctx.text(status, '')
}

// server_error Response a server error
pub fn (mut ctx Context) server_error(ecode int) Result {
	$if debug {
		eprintln('> ctx.server_error ecode: $ecode')
	}
	ctx.send_string(http_500.bytestr()) or {}
	return Result{}
}

// redirect Redirect to an url
pub fn (mut ctx Context) redirect(url string) Result {
	mut resp := http_302
	resp.header = resp.header.join(ctx.header)
	resp.header.add(.location, url)
	ctx.send_string(resp.bytestr()) or { return Result{} }
	return Result{}
}

// not_found Send an not_found response
pub fn (mut ctx Context) not_found() Result {
	return ctx.status(http.Status.not_found)
}

// add_header Adds an header to the response with key and val
pub fn (mut ctx Context) add_header(key string, val string) {
	ctx.header.add_custom(key, val) or {}
}

// get_header Returns the header data from the key
pub fn (ctx &Context) get_header(key string) string {
	return ctx.req.header.get_custom(key) or { '' }
}

interface DbInterface {
	db voidptr
}

// run runs the app
[manualfree]
pub fn run<T>(global_app &T, port int) {
	mut l := net.listen_tcp(.ip6, ':$port') or { panic('failed to listen $err.code() $err') }

	// Parsing methods attributes
	mut routes := map[string]Route{}
	$for method in T.methods {
		http_methods, route_path := parse_attrs(method.name, method.attrs) or {
			eprintln('error parsing method attributes: $err')
			return
		}

		routes[method.name] = Route{
			methods: http_methods
			path: route_path
		}
	}
	println('[Vweb] Running app on http://localhost:$port')
	for {
		// Create a new app object for each connection, copy global data like db connections
		mut request_app := &T{}
		$if T is DbInterface {
			request_app.db = global_app.db
		} $else {
			// println('web no db')
		}
		$for field in T.fields {
			if 'web_global' in field.attrs || field.is_shared {
				request_app.$(field.name) = global_app.$(field.name)
			}
		}
		request_app.Context = global_app.Context // copy the context ref that contains static files map etc
		mut conn := l.accept() or {
			// failures should not panic
			eprintln('accept() failed with error: $err.msg()')
			continue
		}
		go handle_conn<T>(mut conn, mut request_app, routes)
	}
}

// handle_conn handles a connection
[manualfree]
fn handle_conn<T>(mut conn net.TcpConn, mut app T, routes map[string]Route) {
	conn.set_read_timeout(30 * time.second)
	conn.set_write_timeout(30 * time.second)

	defer {
		conn.close() or {}

		lock app.logger {
			app.logger.flush()
		}

		unsafe {
			free(app)
		}
	}

	mut reader := io.new_buffered_reader(reader: conn)
	defer {
		reader.free()
	}

	page_gen_start := time.ticks()

	// Request parse
	head := http.parse_request_head(mut reader) or {
		// Prevents errors from being thrown when BufferedReader is empty
		if '$err' != 'none' {
			eprintln('error parsing request head: $err')
		}
		return
	}

	// The healthcheck spams the logs, which isn't very useful
	if head.url != '/health' {
		lock app.logger {
			app.logger.debug('$head.method $head.url $head.version')
		}
	}

	// 	req := http.parse_request(mut reader) or {
	// 		// Prevents errors from being thrown when BufferedReader is empty
	// 		if '$err' != 'none' {
	// 			eprintln('error parsing request: $err')
	// 		}
	// 		return
	// 	}

	// URL Parse
	url := urllib.parse(head.url) or {
		eprintln('error parsing path: $err')
		return
	}

	// Query parse
	query := parse_query_from_url(url)
	url_words := url.path.split('/').filter(it != '')

	// TODO re-add form parsing
	// Form parse
	// form, files := parse_form_from_request(req) or {
	// 	// Bad request
	// 	conn.write(web.http_400.bytes()) or {}
	// 	return
	// }

	app.Context = Context{
		req: head
		page_gen_start: page_gen_start
		conn: conn
		query: query
		// form: form
		// files: files
		static_files: app.static_files
		static_mime_types: app.static_mime_types
		reader: reader
		logger: app.logger
	}

	// Calling middleware...
	app.before_request()

	// Route matching
	$for method in T.methods {
		$if method.return_type is Result {
			route := routes[method.name] or {
				eprintln('parsed attributes for the `$method.name` are not found, skipping...')
				Route{}
			}

			// Skip if the HTTP request method does not match the attributes
			if head.method in route.methods {
				// Used for route matching
				route_words := route.path.split('/').filter(it != '')

				// Route immediate matches first
				// For example URL `/register` matches route `/:user`, but `fn register()`
				// should be called first.
				if !route.path.contains('/:') && url_words == route_words {
					// We found a match
					if head.method == .post && method.args.len > 0 {
						// TODO implement POST requests
						// Populate method args with form values
						// mut args := []string{cap: method.args.len}
						// for param in method.args {
						// 	args << form[param.name]
						// }
						// app.$method(args)
					} else {
						app.$method()
					}
					return
				}

				if url_words.len == 0 && route_words == ['index'] && method.name == 'index' {
					app.$method()
					return
				}

				if params := route_matches(url_words, route_words) {
					method_args := params.clone()
					if method_args.len != method.args.len {
						eprintln('warning: uneven parameters count ($method.args.len) in `$method.name`, compared to the web route `$method.attrs` ($method_args.len)')
					}
					app.$method(method_args)
					return
				}
			}
		}
	}
	// Route not found
	conn.write(http_404.bytes()) or {}
}

// route_matches returns wether a route matches
fn route_matches(url_words []string, route_words []string) ?[]string {
	// URL path should be at least as long as the route path
	// except for the catchall route (`/:path...`)
	if route_words.len == 1 && route_words[0].starts_with(':') && route_words[0].ends_with('...') {
		return ['/' + url_words.join('/')]
	}
	if url_words.len < route_words.len {
		return none
	}

	mut params := []string{cap: url_words.len}
	if url_words.len == route_words.len {
		for i in 0 .. url_words.len {
			if route_words[i].starts_with(':') {
				// We found a path paramater
				params << url_words[i]
			} else if route_words[i] != url_words[i] {
				// This url does not match the route
				return none
			}
		}
		return params
	}

	// The last route can end with ... indicating an array
	if route_words.len == 0 || !route_words[route_words.len - 1].ends_with('...') {
		return none
	}

	for i in 0 .. route_words.len - 1 {
		if route_words[i].starts_with(':') {
			// We found a path paramater
			params << url_words[i]
		} else if route_words[i] != url_words[i] {
			// This url does not match the route
			return none
		}
	}
	params << url_words[route_words.len - 1..url_words.len].join('/')
	return params
}

// ip Returns the ip address from the current user
pub fn (ctx &Context) ip() string {
	mut ip := ctx.req.header.get(.x_forwarded_for) or { '' }
	if ip == '' {
		ip = ctx.req.header.get_custom('X-Real-Ip') or { '' }
	}

	if ip.contains(',') {
		ip = ip.all_before(',')
	}
	if ip == '' {
		ip = ctx.conn.peer_ip() or { '' }
	}
	return ip
}

// error Set s to the form error
pub fn (mut ctx Context) error(s string) {
	println('web error: $s')
}

// filter Do not delete.
// It used by `vlib/v/gen/c/str_intp.v:130` for string interpolation inside web templates
// TODO: move it to template render
fn filter(s string) string {
	return s.replace_each([
		'<',
		'&lt;',
		'"',
		'&quot;',
		'&',
		'&amp;',
	])
}
