module client

import models { GitRepo, GitRepoFilter }
import net.http { Method }
import response { Response }

// get_git_repos returns a list of GitRepo's, given a filter object.
pub fn (c &Client) get_git_repos(filter GitRepoFilter) ?[]GitRepo {
	params := models.params_from(filter)
	data := c.send_request<[]GitRepo>(Method.get, '/api/repos', params)?

	return data.data
}

// get_all_git_repos retrieves *all* GitRepo's from the API using the default
// limit.
pub fn (c &Client) get_all_git_repos() ?[]GitRepo {
	mut repos := []GitRepo{}
	mut offset := u64(0)

	for {
		sub_repos := c.get_git_repos(offset: offset)?

		if sub_repos.len == 0 {
			break
		}

		repos << sub_repos

		offset += u64(sub_repos.len)
	}

	return repos
}

// get_git_repo returns the repo for a specific ID.
pub fn (c &Client) get_git_repo(id int) ?GitRepo {
	data := c.send_request<GitRepo>(Method.get, '/api/repos/$id', {})?

	return data.data
}

// add_git_repo adds a new repo to the server.
pub fn (c &Client) add_git_repo(url string, branch string, repo string, arch []string) ?Response<string> {
	mut params := {
		'url':    url
		'branch': branch
		'repo':   repo
	}

	if arch.len > 0 {
		params['arch'] = arch.join(',')
	}

	data := c.send_request<string>(Method.post, '/api/repos', params)?

	return data
}

// remove_git_repo removes the repo with the given ID from the server.
pub fn (c &Client) remove_git_repo(id int) ?Response<string> {
	data := c.send_request<string>(Method.delete, '/api/repos/$id', {})?

	return data
}

// patch_git_repo sends a PATCH request to the given repo with the params as
// payload.
pub fn (c &Client) patch_git_repo(id int, params map[string]string) ?Response<string> {
	data := c.send_request<string>(Method.patch, '/api/repos/$id', params)?

	return data
}
