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

// A dummy structure that returns from routes to indicate that you actually sent something to a user
[noinit]
pub struct Result {}

pub const (
	methods_with_form = [http.Method.post, .put, .patch]
	headers_close     = http.new_custom_header_from_map({
		'Server':                           'VWeb'
		http.CommonHeader.connection.str(): 'close'
	}) or { panic('should never fail') }

	http_302          = http.new_response(
		status: .found
		text: '302 Found'
		header: headers_close
	)
	http_400          = http.new_response(
		status: .bad_request
		text: '400 Bad Request'
		header: http.new_header(
			key: .content_type
			value: 'text/plain'
		).join(headers_close)
	)
	http_404          = http.new_response(
		status: .not_found
		text: '404 Not Found'
		header: http.new_header(
			key: .content_type
			value: 'text/plain'
		).join(headers_close)
	)
	http_500          = http.new_response(
		status: .internal_server_error
		text: '500 Internal Server Error'
		header: http.new_header(
			key: .content_type
			value: 'text/plain'
		).join(headers_close)
	)
	mime_types        = {
		'.aac':    'audio/aac'
		'.abw':    'application/x-abiword'
		'.arc':    'application/x-freearc'
		'.avi':    'video/x-msvideo'
		'.azw':    'application/vnd.amazon.ebook'
		'.bin':    'application/octet-stream'
		'.bmp':    'image/bmp'
		'.bz':     'application/x-bzip'
		'.bz2':    'application/x-bzip2'
		'.cda':    'application/x-cdf'
		'.csh':    'application/x-csh'
		'.css':    'text/css'
		'.csv':    'text/csv'
		'.doc':    'application/msword'
		'.docx':   'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
		'.eot':    'application/vnd.ms-fontobject'
		'.epub':   'application/epub+zip'
		'.gz':     'application/gzip'
		'.gif':    'image/gif'
		'.htm':    'text/html'
		'.html':   'text/html'
		'.ico':    'image/vnd.microsoft.icon'
		'.ics':    'text/calendar'
		'.jar':    'application/java-archive'
		'.jpeg':   'image/jpeg'
		'.jpg':    'image/jpeg'
		'.js':     'text/javascript'
		'.json':   'application/json'
		'.jsonld': 'application/ld+json'
		'.mid':    'audio/midi audio/x-midi'
		'.midi':   'audio/midi audio/x-midi'
		'.mjs':    'text/javascript'
		'.mp3':    'audio/mpeg'
		'.mp4':    'video/mp4'
		'.mpeg':   'video/mpeg'
		'.mpkg':   'application/vnd.apple.installer+xml'
		'.odp':    'application/vnd.oasis.opendocument.presentation'
		'.ods':    'application/vnd.oasis.opendocument.spreadsheet'
		'.odt':    'application/vnd.oasis.opendocument.text'
		'.oga':    'audio/ogg'
		'.ogv':    'video/ogg'
		'.ogx':    'application/ogg'
		'.opus':   'audio/opus'
		'.otf':    'font/otf'
		'.png':    'image/png'
		'.pdf':    'application/pdf'
		'.php':    'application/x-httpd-php'
		'.ppt':    'application/vnd.ms-powerpoint'
		'.pptx':   'application/vnd.openxmlformats-officedocument.presentationml.presentation'
		'.rar':    'application/vnd.rar'
		'.rtf':    'application/rtf'
		'.sh':     'application/x-sh'
		'.svg':    'image/svg+xml'
		'.swf':    'application/x-shockwave-flash'
		'.tar':    'application/x-tar'
		'.tif':    'image/tiff'
		'.tiff':   'image/tiff'
		'.ts':     'video/mp2t'
		'.ttf':    'font/ttf'
		'.txt':    'text/plain'
		'.vsd':    'application/vnd.visio'
		'.wav':    'audio/wav'
		'.weba':   'audio/webm'
		'.webm':   'video/webm'
		'.webp':   'image/webp'
		'.woff':   'font/woff'
		'.woff2':  'font/woff2'
		'.xhtml':  'application/xhtml+xml'
		'.xls':    'application/vnd.ms-excel'
		'.xlsx':   'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
		'.xml':    'application/xml'
		'.xul':    'application/vnd.mozilla.xul+xml'
		'.zip':    'application/zip'
		'.3gp':    'video/3gpp'
		'.3g2':    'video/3gpp2'
		'.7z':     'application/x-7z-compressed'
	}
	max_http_post_size = 1024 * 1024
	default_port       = 8080
)

// The Context struct represents the Context which hold the HTTP request and response.
// It has fields for the query, form, files.
pub struct Context {
mut:
	content_type string = 'text/plain'
	status       http.Status    = http.Status.ok
pub:
	// HTTP Request
	req http.Request
	// TODO Response
pub mut:
	done bool
	// time.ticks() from start of web connection handle.
	// You can use it to determine how much time is spent on your request.
	page_gen_start i64
	// TCP connection to client.
	// But beware, do not store it for further use, after request processing web will close connection.
	conn              &net.TcpConn
	static_files      map[string]string
	static_mime_types map[string]string
	// Map containing query params for the route.
	// Example: `http://localhost:3000/index?q=vpm&order_by=desc => { 'q': 'vpm', 'order_by': 'desc' }
	query map[string]string
	// Multipart-form fields.
	form map[string]string
	// Files from multipart-form.
	files map[string][]http.FileData

	header http.Header // response headers
	// ? It doesn't seem to be used anywhere
	form_error string
	// Allows reading the request body
	reader io.BufferedReader
	// Gives access to a shared logger object
	logger shared log.Log
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

// send_string
fn send_string(mut conn net.TcpConn, s string) ? {
	conn.write(s.bytes()) ?
}

// send_response_to_client sends a response to the client
[manualfree]
pub fn (mut ctx Context) send_response_to_client(mimetype string, res string) bool {
	if ctx.done {
		return false
	}
	ctx.done = true

	// build header
	header := http.new_header_from_map({
		http.CommonHeader.content_type:   mimetype
		http.CommonHeader.content_length: res.len.str()
	}).join(ctx.header)

	mut resp := http.Response{
		header: header.join(web.headers_close)
		text: res
	}
	resp.set_version(.v1_1)
	resp.set_status(ctx.status)
	send_string(mut ctx.conn, resp.bytestr()) or { return false }
	return true
}

pub fn (mut ctx Context) text(status http.Status, s string) Result {
	ctx.status = status

	ctx.send_response_to_client('text/plain', s)

	return Result{}
}

// json<T> HTTP_OK with json_s as payload with content-type `application/json`
pub fn (mut ctx Context) json<T>(status http.Status, j T) Result {
	ctx.status = status

	json_s := json.encode(j)
	ctx.send_response_to_client('application/json', json_s)
	return Result{}
}

// file Response HTTP_OK with file as payload
// This function manually implements responses because it needs to stream the file contents
pub fn (mut ctx Context) file(f_path string) Result {
	if ctx.done {
		return Result{}
	}

	if !os.is_file(f_path) {
		return ctx.not_found()
	}

	// ext := os.file_ext(f_path)
	// data := os.read_file(f_path) or {
	// 	eprint(err.msg)
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

	file := os.open(f_path) or {
		eprintln(err.msg)
		ctx.server_error(500)
		return Result{}
	}

	// build header
	header := http.new_header_from_map({
		// http.CommonHeader.content_type:   content_type
		http.CommonHeader.content_length: file_size.str()
	}).join(ctx.header)

	mut resp := http.Response{
		header: header.join(web.headers_close)
	}
	resp.set_version(.v1_1)
	resp.set_status(ctx.status)
	send_string(mut ctx.conn, resp.bytestr()) or { return Result{} }

	mut buf := []byte{len: 1_000_000}
	mut bytes_left := file_size

	// Repeat as long as the stream still has data
	for bytes_left > 0 {
		// TODO check if just breaking here is safe
		bytes_read := file.read(mut buf) or { break }
		bytes_left -= u64(bytes_read)

		mut to_write := bytes_read

		for to_write > 0 {
			// TODO don't just loop infinitely here
			bytes_written := ctx.conn.write(buf[bytes_read - to_write..bytes_read]) or { continue }

			to_write = to_write - bytes_written
		}
	}

	ctx.done = true
	return Result{}
}

pub fn (mut ctx Context) status(status http.Status) Result {
	return ctx.text(status, '')
}

// server_error Response a server error
pub fn (mut ctx Context) server_error(ecode int) Result {
	$if debug {
		eprintln('> ctx.server_error ecode: $ecode')
	}
	if ctx.done {
		return Result{}
	}
	send_string(mut ctx.conn, web.http_500.bytestr()) or {}
	return Result{}
}

// redirect Redirect to an url
pub fn (mut ctx Context) redirect(url string) Result {
	if ctx.done {
		return Result{}
	}
	ctx.done = true
	mut resp := web.http_302
	resp.header = resp.header.join(ctx.header)
	resp.header.add(.location, url)
	send_string(mut ctx.conn, resp.bytestr()) or { return Result{} }
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
	mut l := net.listen_tcp(.ip6, ':$port') or { panic('failed to listen $err.code $err') }

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
			eprintln('accept() failed with error: $err.msg')
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
	conn.write(web.http_404.bytes()) or {}
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
	ctx.form_error = s
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
