module client

import net.http { Method }
import net.urllib
import response { Response }
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
fn (c &Client) send_request_raw(method Method, url string, params map[string]string, body string) ?http.Response {
	mut full_url := '$c.address$url'

	if params.len > 0 {
		mut params_escaped := map[string]string{}

		// Escape each query param
		for k, v in params {
			// An empty parameter should be the same as not providing it at all
			if v != '' {
				params_escaped[k] = urllib.query_escape(v)
			}
		}

		params_str := params_escaped.keys().map('$it=${params[it]}').join('&')

		full_url = '$full_url?$params_str'
	}

	mut req := http.new_request(method, full_url, body)?
	req.add_custom_header('X-Api-Key', c.api_key)?

	res := req.do()?

	return res
}

// send_request<T> just calls send_request_with_body<T> with an empty body.
fn (c &Client) send_request<T>(method Method, url string, params map[string]string) ?Response<T> {
	return c.send_request_with_body<T>(method, url, params, '')
}

// send_request_with_body<T> calls send_request_raw_response & parses its
// output as a Response<T> object.
fn (c &Client) send_request_with_body<T>(method Method, url string, params map[string]string, body string) ?Response<T> {
	res_text := c.send_request_raw_response(method, url, params, body)?
	data := json.decode(Response<T>, res_text)?

	return data
}

// send_request_raw_response returns the raw text response for an HTTP request.
fn (c &Client) send_request_raw_response(method Method, url string, params map[string]string, body string) ?string {
	res := c.send_request_raw(method, url, params, body)?

	return res.text
}
