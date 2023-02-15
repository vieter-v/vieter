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
import metrics

// The Context struct represents the Context which hold the HTTP request and response.
// It has fields for the query, form, files.
pub struct Context {
pub:
	// HTTP Request
	req http.Request
	// API key used when authenticating requests
	api_key string
	// TODO Response
pub mut:
	// TCP connection to client.
	// But beware, do not store it for further use, after request processing web will close connection.
	conn &net.TcpConn = unsafe { nil }
	// Gives access to a shared logger object
	logger shared log.Log
	// Used to collect metrics on the web server
	collector &metrics.MetricsCollector
	// time.ticks() from start of web connection handle.
	// You can use it to determine how much time is spent on your request.
	page_gen_start i64
	// REQUEST
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
	reader &io.BufferedReader = unsafe { nil }
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
fn (mut ctx Context) send_string(s string) ! {
	ctx.conn.write(s.bytes())!
}

// send_reader reads at most `size` bytes from the given reader & writes them
// to the TCP connection socket. Internally, a 10KB buffer is used, to avoid
// having to store all bytes in memory at once.
fn (mut ctx Context) send_reader(mut reader io.Reader, size u64) ! {
	mut buf := []u8{len: 10_000}
	mut bytes_left := size

	// Repeat as long as the stream still has data
	for bytes_left > 0 {
		bytes_read := reader.read(mut buf)!
		bytes_left -= u64(bytes_read)

		mut to_write := bytes_read

		for to_write > 0 {
			bytes_written := ctx.conn.write(buf[bytes_read - to_write..bytes_read]) or { break }

			to_write = to_write - bytes_written
		}
	}
}

// send_custom_response sends the given http.Response to the client. It can be
// used to overwrite the Context object & send a completely custom
// http.Response instead.
fn (mut ctx Context) send_custom_response(resp &http.Response) ! {
	ctx.send_string(resp.bytestr())!
}

// send_response_header constructs a valid HTTP response with an empty body &
// sends it to the client.
pub fn (mut ctx Context) send_response_header() ! {
	mut resp := http.new_response(
		header: ctx.header.join(headers_close)
	)
	resp.header.add(.content_type, ctx.content_type)
	resp.set_status(ctx.status)

	ctx.send_custom_response(resp)!
}

// send is a convenience function for sending the HTTP response with an empty
// body.
pub fn (mut ctx Context) send() bool {
	return ctx.send_response('')
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

// is_authenticated checks whether the request passes a correct API key.
pub fn (ctx &Context) is_authenticated() bool {
	if provided_key := ctx.req.header.get_custom('X-Api-Key') {
		return provided_key == ctx.api_key
	}

	return false
}

// body sends the given body as an HTTP response.
pub fn (mut ctx Context) body(status http.Status, content_type string, body string) Result {
	ctx.status = status
	ctx.content_type = content_type
	ctx.send_response(body)

	return Result{}
}

// json[T] HTTP_OK with json_s as payload with content-type `application/json`
pub fn (mut ctx Context) json[T](status http.Status, j T) Result {
	ctx.status = status
	ctx.content_type = 'application/json'

	json_s := json.encode(j)
	ctx.send_response(json_s)

	return Result{}
}

// file Response HTTP_OK with file as payload
// This function manually implements responses because it needs to stream the file contents
pub fn (mut ctx Context) file(f_path string) Result {
	// If the file doesn't exist, just respond with a 404
	if !os.is_file(f_path) {
		ctx.status = .not_found
		ctx.send()

		return Result{}
	}

	ctx.header.add(.accept_ranges, 'bytes')

	file_size := os.file_size(f_path)
	ctx.header.add(http.CommonHeader.content_length, file_size.str())

	// A HEAD request only returns the size of the file.
	if ctx.req.method == .head {
		ctx.send()

		return Result{}
	}

	mut file := os.open(f_path) or {
		eprintln(err.msg())
		ctx.server_error(500)
		return Result{}
	}

	defer {
		file.close()
	}

	// Currently, this only supports a single provided range, e.g.
	// bytes=0-1023, and not multiple ranges, e.g. bytes=0-50, 100-150
	if range_str := ctx.req.header.get(.range) {
		mut parts := range_str.split_nth('=', 2)

		// We only support the 'bytes' range type
		if parts[0] != 'bytes' {
			ctx.status = .requested_range_not_satisfiable
			ctx.header.delete(.content_length)
			ctx.send()
			return Result{}
		}

		parts = parts[1].split_nth('-', 2)

		start := parts[0].i64()
		end := if parts[1] == '' { file_size - 1 } else { parts[1].u64() }

		// Either the actual number 0 or the result of an invalid integer
		if end == 0 {
			ctx.status = .requested_range_not_satisfiable
			ctx.header.delete(.content_length)
			ctx.send()
			return Result{}
		}

		// Move cursor to start of data to read
		file.seek(start, .start) or {
			ctx.server_error(500)
			return Result{}
		}

		length := end - u64(start) + 1

		ctx.status = .partial_content
		ctx.header.set(.content_length, length.str())
		ctx.send_reader_response(mut file, length)
	} else {
		ctx.send_reader_response(mut file, file_size)
	}

	return Result{}
}

// status responds with an empty textual response, essentially only returning
// the given status code.
pub fn (mut ctx Context) status(status http.Status) Result {
	ctx.status = status
	ctx.send()

	return Result{}
}

// server_error Response a server error
pub fn (mut ctx Context) server_error(ecode int) Result {
	ctx.send_custom_response(http_500) or {}

	return Result{}
}

// redirect Redirect to an url
pub fn (mut ctx Context) redirect(url string) Result {
	mut resp := http_302
	resp.header = resp.header.join(ctx.header)
	resp.header.add(.location, url)

	ctx.send_custom_response(resp) or {}

	return Result{}
}

interface DbInterface {
	db voidptr
}

// run runs the app
[manualfree]
pub fn run[T](global_app &T, port int) {
	mut l := net.listen_tcp(.ip6, ':${port}') or { panic('failed to listen ${err.code()} ${err}') }

	// Parsing methods attributes
	mut routes := map[string]Route{}
	$for method in T.methods {
		http_methods, route_path := parse_attrs(method.name, method.attrs) or {
			eprintln('error parsing method attributes: ${err}')
			return
		}

		routes[method.name] = Route{
			methods: http_methods
			path: route_path
		}
	}
	println('[Vweb] Running app on http://localhost:${port}')
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
			eprintln('accept() failed with error: ${err.msg()}')
			continue
		}
		spawn handle_conn[T](mut conn, mut request_app, routes)
	}
}

// handle_conn handles a connection
[manualfree]
fn handle_conn[T](mut conn net.TcpConn, mut app T, routes map[string]Route) {
	conn.set_read_timeout(30 * time.second)
	conn.set_write_timeout(30 * time.second)

	defer {
		conn.close() or {}

		lock app.logger {
			app.logger.flush()
		}

		// Record how long request took to process
		labels := [
			['method', app.req.method.str()]!,
			['path', app.req.url]!,
			// Not all methods properly set this value yet I think
			['status', app.status.int().str()]!,
		]
		app.collector.counter_increment(name: 'http_requests_total', labels: labels)
		// Prometheus prefers metrics containing base units, as defined here
		// https://prometheus.io/docs/practices/naming/
		app.collector.histogram_record(f64(time.ticks() - app.page_gen_start) / 1000,
			
			name: 'http_requests_duration_seconds'
			labels: labels
		)

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
		if '${err}' != 'none' {
			eprintln('error parsing request head: ${err}')
		}
		return
	}

	// The healthcheck spams the logs, which isn't very useful
	if head.url != '/health' {
		lock app.logger {
			app.logger.debug('${head.method} ${head.url} ${head.version}')
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
		eprintln('error parsing path: ${err}')
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
		collector: app.collector
		api_key: app.api_key
	}

	// Calling middleware...
	app.before_request()

	// Route matching
	$for method in T.methods {
		$if method.return_type is Result {
			route := routes[method.name] or {
				eprintln('parsed attributes for the `${method.name}` are not found, skipping...')
				Route{}
			}

			// Skip if the HTTP request method does not match the attributes
			if head.method in route.methods {
				// Used for route matching
				route_words := route.path.split('/').filter(it != '')

				// Route immediate matches & index files first
				// For example URL `/register` matches route `/:user`, but `fn register()`
				// should be called first.
				if (!route.path.contains('/:') && url_words == route_words)
					|| (url_words.len == 0 && route_words == ['index'] && method.name == 'index') {
					// Check whether the request is authorised
					if 'auth' in method.attrs && !app.is_authenticated() {
						conn.write(http_401.bytes()) or {}
						return
					}

					// We found a match
					app.$method()
					return
				} else if params := route_matches(url_words, route_words) {
					// Check whether the request is authorised
					if 'auth' in method.attrs && !app.is_authenticated() {
						conn.write(http_401.bytes()) or {}
						return
					}

					method_args := params.clone()
					if method_args.len != method.args.len {
						eprintln('warning: uneven parameters count (${method.args.len}) in `${method.name}`, compared to the web route `${method.attrs}` (${method_args.len})')
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
