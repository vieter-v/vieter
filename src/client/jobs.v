module client

import build { BuildConfig }

// poll_jobs requests a list of new build jobs from the server.
pub fn (c &Client) poll_jobs(arch string, max int) ![]BuildConfig {
	data := c.send_request<[]BuildConfig>(.get, '/api/v1/jobs/poll', {
		'arch': arch
		'max':  max.str()
	})!

	return data.data
}

// queue_job adds a new one-time build job for the given target to the job
// queue.
pub fn (c &Client) queue_job(target_id int, arch string, force bool) ! {
	c.send_request<string>(.post, '/api/v1/jobs/queue', {
		'target': target_id.str()
		'arch':   arch
		'force':  force.str()
	})!
}
