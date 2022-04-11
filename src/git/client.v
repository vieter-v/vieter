module git

import json
import response { Response }
import net.http

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
pub fn get_repos(address string, api_key string) ?map[string]GitRepo {
	data := send_request<map[string]GitRepo>(http.Method.get, address, '/api/repos', api_key,
		{}) ?

	return data.data
}

// add_repo adds a new repo to the server.
pub fn add_repo(address string, api_key string, url string, branch string, repo string, arch []string) ?Response<string> {
	params := {
		'url':    url
		'branch': branch
		'repo':   repo
		'arch':   arch.join(',')
	}
	data := send_request<string>(http.Method.post, address, '/api/repos', api_key, params) ?

	return data
}

// remove_repo removes the repo with the given ID from the server.
pub fn remove_repo(address string, api_key string, id string) ?Response<string> {
	data := send_request<string>(http.Method.delete, address, '/api/repos/$id', api_key,
		{}) ?

	return data
}

// patch_repo sends a PATCH request to the given repo with the params as
// payload.
pub fn patch_repo(address string, api_key string, id string, params map[string]string) ?Response<string> {
	data := send_request<string>(http.Method.patch, address, '/api/repos/$id', api_key,
		params) ?

	return data
}