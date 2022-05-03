module git

import json
import response { Response }
import net.http
import db

// send_request<T> is a convenience method for sending requests to the repos
// API. It mostly does string manipulation to create a query string containing
// the provided params.
fn send_request<T>(method http.Method, address string, url string, api_key string, params map[string]string) ?Response<T> {
	mut full_url := '$address$url'

	if params.len > 0 {
		params_str := params.keys().map('$it=${params[it]}').join('&')

		full_url = '$full_url?$params_str'
	}

	mut req := http.new_request(method, full_url, '') ?
	req.add_custom_header('X-API-Key', api_key) ?

	res := req.do() ?
	data := json.decode(Response<T>, res.text) ?

	return data
}

// get_repos returns the current list of repos.
pub fn get_repos(address string, api_key string) ?[]db.GitRepo {
	data := send_request<[]db.GitRepo>(http.Method.get, address, '/api/repos', api_key,
		{}) ?

	return data.data
}

pub fn get_repo(address string, api_key string, id int) ?db.GitRepo {
	data := send_request<db.GitRepo>(http.Method.get, address, '/api/repos/$id', api_key,
		{}) ?

	return data.data
}

// add_repo adds a new repo to the server.
pub fn add_repo(address string, api_key string, url string, branch string, repo string, arch []string) ?Response<string> {
	mut params := {
		'url':    url
		'branch': branch
		'repo':   repo
	}

	if arch.len > 0 {
		params['arch'] = arch.join(',')
	}

	data := send_request<string>(http.Method.post, address, '/api/repos', api_key, params) ?

	return data
}

// remove_repo removes the repo with the given ID from the server.
pub fn remove_repo(address string, api_key string, id int) ?Response<string> {
	data := send_request<string>(http.Method.delete, address, '/api/repos/$id', api_key,
		{}) ?

	return data
}

// patch_repo sends a PATCH request to the given repo with the params as
// payload.
pub fn patch_repo(address string, api_key string, id int, params map[string]string) ?Response<string> {
	data := send_request<string>(http.Method.patch, address, '/api/repos/$id', api_key,
		params) ?

	return data
}
