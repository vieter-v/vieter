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
