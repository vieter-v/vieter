module client

import db { BuildLog }
import net.http { Method }
import response { Response }
import time

pub fn (c &Client) get_build_logs() ?Response<[]BuildLog> {
	data := c.send_request<[]BuildLog>(Method.get, '/api/logs', {}) ?

	return data
}

pub fn (c &Client) get_build_logs_for_repo(repo_id int) ?Response<[]BuildLog> {
	params := {
		'repo': repo_id.str()
	}

	data := c.send_request<[]BuildLog>(Method.get, '/api/logs', params) ?

	return data
}

pub fn (c &Client) get_build_log(id int) ?Response<BuildLog> {
	data := c.send_request<BuildLog>(Method.get, '/api/logs/$id', {}) ?

	return data
}

pub fn (c &Client) get_build_log_content(id int) ?string {
	data := c.send_request_raw_response(Method.get, '/api/logs/$id/content', {}, '') ?

	return data
}

pub fn (c &Client) add_build_log(repo_id int, start_time time.Time, end_time time.Time, arch string, exit_code int, content string) ?Response<string> {
	params := {
		'repo':      repo_id.str()
		'startTime': start_time.str()
		'endTime':   end_time.str()
		'arch':      arch
		'exitCode':  exit_code.str()
	}

	data := c.send_request_with_body<string>(Method.post, '/api/logs', params, content) ?

	return data
}
