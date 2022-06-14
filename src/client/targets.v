module client

import models { GitRepo, GitRepoFilter }
import net.http { Method }
import response { Response }

// get_targets returns a list of GitRepo's, given a filter object.
pub fn (c &Client) get_targets(filter GitRepoFilter) ?[]GitRepo {
	params := models.params_from(filter)
	data := c.send_request<[]GitRepo>(Method.get, '/api/v1/targets', params)?

	return data.data
}

// get_all_targets retrieves *all* GitRepo's from the API using the default
// limit.
pub fn (c &Client) get_all_targets() ?[]GitRepo {
	mut repos := []GitRepo{}
	mut offset := u64(0)

	for {
		sub_repos := c.get_targets(offset: offset)?

		if sub_repos.len == 0 {
			break
		}

		repos << sub_repos

		offset += u64(sub_repos.len)
	}

	return repos
}

// get_target returns the repo for a specific ID.
pub fn (c &Client) get_target(id int) ?GitRepo {
	data := c.send_request<GitRepo>(Method.get, '/api/v1/targets/$id', {})?

	return data.data
}

// add_target adds a new repo to the server.
pub fn (c &Client) add_target(url string, branch string, repo string, arch []string) ?Response<string> {
	mut params := {
		'url':    url
		'branch': branch
		'repo':   repo
	}

	if arch.len > 0 {
		params['arch'] = arch.join(',')
	}

	data := c.send_request<string>(Method.post, '/api/v1/targets', params)?

	return data
}

// remove_target removes the repo with the given ID from the server.
pub fn (c &Client) remove_target(id int) ?Response<string> {
	data := c.send_request<string>(Method.delete, '/api/v1/targets/$id', {})?

	return data
}

// patch_target sends a PATCH request to the given repo with the params as
// payload.
pub fn (c &Client) patch_target(id int, params map[string]string) ?Response<string> {
	data := c.send_request<string>(Method.patch, '/api/v1/targets/$id', params)?

	return data
}
