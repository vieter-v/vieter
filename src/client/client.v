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

pub fn new(address string, api_key string) Client {
	return Client{
		address: address
		api_key: api_key
	}
}

fn (c &Client) send_request_raw(method Method, url string, params map[string]string, body string) ?http.Response {
	mut full_url := '$c.address$url'

	if params.len > 0 {
		mut params_escaped := map[string]string{}

		// Escape each query param
		for k, v in params {
			params_escaped[k] = urllib.query_escape(v)
		}

		params_str := params_escaped.keys().map('$it=${params[it]}').join('&')

		full_url = '$full_url?$params_str'
	}

	mut req := http.new_request(method, full_url, body) ?
	req.add_custom_header('X-Api-Key', c.api_key) ?

	res := req.do() ?

	return res
}

// send_request<T> just calls send_request_with_body<T> with an empty body.
fn (c &Client) send_request<T>(method Method, url string, params map[string]string) ?Response<T> {
	return c.send_request_with_body<T>(method, url, params, '')
}

// send_request_with_body<T> is a convenience method for sending requests to
// the repos API. It mostly does string manipulation to create a query string
// containing the provided params.
fn (c &Client) send_request_with_body<T>(method Method, url string, params map[string]string, body string) ?Response<T> {
	res_text := c.send_request_raw_response(method, url, params, body) ?
	data := json.decode(Response<T>, res_text) ?

	return data
}

fn (c &Client) send_request_raw_response(method Method, url string, params map[string]string, body string) ?string {
	res := c.send_request_raw(method, url, params, body) ?

	return res.text
}
