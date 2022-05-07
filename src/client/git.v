module client

import db
import net.http
import response { Response }

// get_repos returns the current list of repos.
pub fn (c &Client) get_git_repos() ?[]db.GitRepo {
	data := c.send_request<[]db.GitRepo>(http.Method.get, '/api/repos', {}) ?

	return data.data
}

// get_repo returns the repo for a specific ID.
pub fn (c &Client) get_git_repo(id int) ?db.GitRepo {
	data := c.send_request<db.GitRepo>(http.Method.get, '/api/repos/$id', {}) ?

	return data.data
}

// add_repo adds a new repo to the server.
pub fn (c &Client) add_git_repo(url string, branch string, repo string, arch []string) ?Response<string> {
	mut params := {
		'url':    url
		'branch': branch
		'repo':   repo
	}

	if arch.len > 0 {
		params['arch'] = arch.join(',')
	}

	data := c.send_request<string>(http.Method.post, '/api/repos', params) ?

	return data
}

// remove_repo removes the repo with the given ID from the server.
pub fn (c &Client) remove_git_repo(id int) ?Response<string> {
	data := c.send_request<string>(http.Method.delete, '/api/repos/$id', {}) ?

	return data
}

// patch_repo sends a PATCH request to the given repo with the params as
// payload.
pub fn (c &Client) patch_git_repo(id int, params map[string]string) ?Response<string> {
	data := c.send_request<string>(http.Method.patch, '/api/repos/$id', params) ?

	return data
}
