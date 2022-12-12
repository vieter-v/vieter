module client

import build { BuildConfig }

pub fn (c &Client) poll_jobs(max int) ![]BuildConfig {
	data := c.send_request<[]BuildConfig>(.get, '/api/v1/jobs/poll', {
		'max': max.str()
	})!

	return data.data
}
