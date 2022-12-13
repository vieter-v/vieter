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

['/api/v1/jobs/queue'; auth; post]
fn (mut app App) v1_queue_job() web.Result {
	target_id := app.query['target'] or {
		return app.json(.bad_request, new_response('Missing target query arg.'))
	}.int()

	arch := app.query['arch'] or {
		return app.json(.bad_request, new_response('Missing arch query arg.'))
	}

	target := app.db.get_target(target_id) or {
		return app.json(.bad_request, new_response('Unknown target id.'))
	}

	app.job_queue.insert(target: target, arch: arch, single: true) or {
		return app.status(.internal_server_error)
	}

	return app.status(.ok)
}
