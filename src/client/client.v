module client

import net.http
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

// send_request<T> is a convenience method for sending requests to the repos
// API. It mostly does string manipulation to create a query string containing
// the provided params.
fn (c &Client) send_request<T>(method http.Method, url string, params map[string]string) ?Response<T> {
	mut full_url := '${c.address}$url'

	if params.len > 0 {
		params_str := params.keys().map('$it=${params[it]}').join('&')

		full_url = '$full_url?$params_str'
	}

	mut req := http.new_request(method, full_url, '') ?
	req.add_custom_header('X-API-Key', c.api_key) ?

	res := req.do() ?
	data := json.decode(Response<T>, res.text) ?

	return data
}

