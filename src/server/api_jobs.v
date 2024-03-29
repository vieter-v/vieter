module server

import web
import web.response { new_data_response, new_response }

// v1_poll_job_queue allows agents to poll for new build jobs.
['/api/v1/jobs/poll'; auth; get; markused]
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

// v1_queue_job allows queueing a new one-time build job for the given target.
['/api/v1/jobs/queue'; auth; markused; post]
fn (mut app App) v1_queue_job() web.Result {
	target_id := app.query['target'] or {
		return app.json(.bad_request, new_response('Missing target query arg.'))
	}.int()

	arch := app.query['arch'] or {
		return app.json(.bad_request, new_response('Missing arch query arg.'))
	}

	if arch == '' {
		app.json(.bad_request, new_response('Empty arch query arg.'))
	}

	force := 'force' in app.query

	target := app.db.get_target(target_id) or {
		return app.json(.bad_request, new_response('Unknown target id.'))
	}

	app.job_queue.insert(target: target, arch: arch, single: true, now: true, force: force) or {
		return app.status(.internal_server_error)
	}

	return app.status(.ok)
}
