module client

import net.http { Method, Status }
import net.urllib
import web.response { Response, new_data_response }
import json

pub struct Client {
pub:
	address string
	api_key string
}

// new creates a new Client instance.
pub fn new(address string, api_key string) Client {
	return Client{
		address: address
		api_key: api_key
	}
}

// send_request_raw sends an HTTP request, returning the http.Response object.
// It encodes the params so that they're safe to pass as HTTP query parameters.
fn (c &Client) send_request_raw(method Method, url string, params map[string]string, body string) !http.Response {
	mut full_url := '$c.address$url'

	if params.len > 0 {
		mut params_escaped := map[string]string{}

		// Escape each query param
		for k, v in params {
			// An empty parameter should be the same as not providing it at all
			params_escaped[k] = urllib.query_escape(v)
		}

		params_str := params_escaped.keys().map('$it=${params_escaped[it]}').join('&')

		full_url = '$full_url?$params_str'
	}

	// Looking at the source code, this function doesn't actually fail, so I'm
	// not sure why it returns an optional
	mut req := http.new_request(method, full_url, body) or { return error('') }
	req.add_custom_header('X-Api-Key', c.api_key)!

	res := req.do()!

	return res
}

// send_request<T> just calls send_request_with_body<T> with an empty body.
fn (c &Client) send_request<T>(method Method, url string, params map[string]string) !Response<T> {
	return c.send_request_with_body<T>(method, url, params, '')
}

// send_request_with_body<T> calls send_request_raw_response & parses its
// output as a Response<T> object.
fn (c &Client) send_request_with_body<T>(method Method, url string, params map[string]string, body string) !Response<T> {
	res := c.send_request_raw(method, url, params, body)!

	// Just return an empty successful response
	if res.status_code == Status.no_content.int() {
		return new_data_response(T{})
	}

	// Non-successful requests are expected to return either an empty body or
	// Response<string>
	if res.status_code < 200 || res.status_code > 299 {
		status_string := http.status_from_int(res.status_code).str()

		// A non-successful status call will have an empty body
		if res.body == '' {
			return error('Error $res.status_code ($status_string): (empty response)')
		}

		data := json.decode(Response<string>, res.body)!

		return error('Status $res.status_code ($status_string): $data.message')
	}

	data := json.decode(Response<T>, res.body)!

	return data
}

// send_request_raw_response returns the raw text response for an HTTP request.
fn (c &Client) send_request_raw_response(method Method, url string, params map[string]string, body string) !string {
	res := c.send_request_raw(method, url, params, body)!

	return res.body
}
