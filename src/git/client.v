module git

import json
import response { Response }
import net.http

fn get_repos(address string, api_key string) ?map[string]GitRepo {
	mut req := http.new_request(http.Method.get, '$address/api/repos', '') ?
	req.add_custom_header('X-API-Key', api_key) ?

	res := req.do() ?
	data := json.decode(Response<map[string]GitRepo>, res.text) ?

	return data.data
}

fn add_repo(address string, api_key string, url string, branch string, arch []string) ?Response<string> {
	mut req := http.new_request(http.Method.post, '$address/api/repos?url=$url&branch=$branch&arch=${arch.join(',')}',
		'') ?
	req.add_custom_header('X-API-Key', api_key) ?

	res := req.do() ?
	data := json.decode(Response<string>, res.text) ?

	return data
}

fn remove_repo(address string, api_key string, id string) ?Response<string> {
	mut req := http.new_request(http.Method.delete, '$address/api/repos/$id', '') ?
	req.add_custom_header('X-API-Key', api_key) ?

	res := req.do() ?
	data := json.decode(Response<string>, res.text) ?

	return data
}
