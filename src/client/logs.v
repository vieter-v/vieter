module client

import models { BuildLog, BuildLogFilter }
import net.http { Method }
import response { Response }
import time

// get_build_logs returns all build logs.
pub fn (c &Client) get_build_logs(filter BuildLogFilter) ?Response<[]BuildLog> {
	params := models.params_from(filter)
	data := c.send_request<[]BuildLog>(Method.get, '/api/v1/logs', params)?

	return data
}

// get_build_logs_for_repo returns all build logs for a given repo.
pub fn (c &Client) get_build_logs_for_repo(repo_id int) ?Response<[]BuildLog> {
	params := {
		'repo': repo_id.str()
	}

	data := c.send_request<[]BuildLog>(Method.get, '/api/v1/logs', params)?

	return data
}

// get_build_log returns a specific build log.
pub fn (c &Client) get_build_log(id int) ?Response<BuildLog> {
	data := c.send_request<BuildLog>(Method.get, '/api/v1/logs/$id', {})?

	return data
}

// get_build_log_content returns the contents of the build log file.
pub fn (c &Client) get_build_log_content(id int) ?string {
	data := c.send_request_raw_response(Method.get, '/api/v1/logs/$id/content', {}, '')?

	return data
}

// add_build_log adds a new build log to the server.
pub fn (c &Client) add_build_log(repo_id int, start_time time.Time, end_time time.Time, arch string, exit_code int, content string) ?Response<string> {
	params := {
		'repo':      repo_id.str()
		'startTime': start_time.unix_time().str()
		'endTime':   end_time.unix_time().str()
		'arch':      arch
		'exitCode':  exit_code.str()
	}

	data := c.send_request_with_body<string>(Method.post, '/api/v1/logs', params, content)?

	return data
}
