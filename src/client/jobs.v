module client

import build { BuildConfig }
import web.response { Response }

// poll_jobs requests a list of new build jobs from the server.
pub fn (c &Client) poll_jobs(arch string, max int) ![]BuildConfig {
	data := c.send_request<[]BuildConfig>(.get, '/api/v1/jobs/poll', {
		'arch': arch
		'max':  max.str()
	})!

	return data.data
}

pub fn (c &Client) queue_job(target_id int, arch string, force bool) !Response<string> {
	data := c.send_request<string>(.post, '/api/v1/jobs/queue', {
		'target': target_id.str()
		'arch':   arch
		'force':  force.str()
	})!

	return data
}
