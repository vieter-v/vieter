module client

import models { BuildLog, BuildLogFilter }
import net.http { Method }
import web.response { Response }
import time

// get_build_logs returns all build logs.
pub fn (c &Client) get_build_logs(filter BuildLogFilter) ![]BuildLog {
	params := models.params_from(filter)
	data := c.send_request<[]BuildLog>(Method.get, '/api/v1/logs', params)!

	return data.data
}

// get_build_log returns a specific build log.
pub fn (c &Client) get_build_log(id int) !BuildLog {
	data := c.send_request<BuildLog>(Method.get, '/api/v1/logs/$id', {})!

	return data.data
}

// get_build_log_content returns the contents of the build log file.
pub fn (c &Client) get_build_log_content(id int) !string {
	data := c.send_request_raw_response(Method.get, '/api/v1/logs/$id/content', {}, '')!

	return data
}

// add_build_log adds a new build log to the server.
pub fn (c &Client) add_build_log(target_id int, start_time time.Time, end_time time.Time, arch string, exit_code int, content string) !Response<int> {
	params := {
		'target':    target_id.str()
		'startTime': start_time.unix_time().str()
		'endTime':   end_time.unix_time().str()
		'arch':      arch
		'exitCode':  exit_code.str()
	}

	data := c.send_request_with_body<int>(Method.post, '/api/v1/logs', params, content)!

	return data
}

// remove_build_log removes the build log with the given id from the server.
pub fn (c &Client) remove_build_log(id int) ! {
	c.send_request<string>(.delete, '/api/v1/logs/$id', {})!
}
