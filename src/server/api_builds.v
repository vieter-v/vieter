module server

import web
import web.response { new_data_response, new_response }

// v1_poll_job_queue allows agents to poll for new build jobs.
['/api/v1/jobs/poll'; auth; get]
fn (mut app App) v1_poll_job_queue() web.Result {
	arch := app.query['arch'] or {
		return app.json(.bad_request, new_response('Missing arch query arg.'))
	}

	max_str := app.query['max'] or {
		return app.json(.bad_request, new_response('Missing max query arg.'))
	}
	max := max_str.int()

	mut out := app.job_queue.pop_n(arch, max).map(it.config)

	return app.json(.ok, new_data_response(out))
}
