module server

import web
import net.http
import web.response { new_data_response, new_response }
import db
import models { Target, TargetArch, TargetFilter }

// v1_get_targets returns the current list of targets.
['/api/v1/targets'; auth; get]
fn (mut app App) v1_get_targets() web.Result {
	filter := models.from_params<TargetFilter>(app.query) or {
		return app.json(http.Status.bad_request, new_response('Invalid query parameters.'))
	}
	targets := app.db.get_targets(filter)

	return app.json(.ok, new_data_response(targets))
}

// v1_get_single_target returns the information for a single target.
['/api/v1/targets/:id'; auth; get]
fn (mut app App) v1_get_single_target(id int) web.Result {
	target := app.db.get_target(id) or { return app.not_found() }

	return app.json(.ok, new_data_response(target))
}

// v1_post_target creates a new target from the provided query string.
['/api/v1/targets'; auth; post]
fn (mut app App) v1_post_target() web.Result {
	mut params := app.query.clone()

	// If a target is created without specifying the arch, we assume it's meant
	// for the default architecture.
	if 'arch' !in params || params['arch'] == '' {
		params['arch'] = app.conf.default_arch
	}

	mut new_target := models.from_params<Target>(params) or {
		return app.json(http.Status.bad_request, new_response(err.msg()))
	}

	// Ensure someone doesn't submit an invalid kind
	if new_target.kind !in models.valid_kinds {
		return app.json(http.Status.bad_request, new_response('Invalid kind.'))
	}

	id := app.db.add_target(new_target)
	new_target.id = id

	// Add the target to the job queue
	// TODO return better error here if it's the cron schedule that's incorrect
	app.job_queue.insert_all(new_target) or { return app.status(.internal_server_error) }

	return app.json(.ok, new_data_response(id))
}

// v1_delete_target removes a given target from the server's list.
['/api/v1/targets/:id'; auth; delete]
fn (mut app App) v1_delete_target(id int) web.Result {
	app.db.delete_target(id)
	app.job_queue.invalidate(id)

	return app.json(.ok, new_response(''))
}

// v1_patch_target updates a target's data with the given query params.
['/api/v1/targets/:id'; auth; patch]
fn (mut app App) v1_patch_target(id int) web.Result {
	app.db.update_target(id, app.query)

	if 'arch' in app.query {
		arch_objs := app.query['arch'].split(',').map(TargetArch{ value: it })

		app.db.update_target_archs(id, arch_objs)
	}

	target := app.db.get_target(id) or { return app.status(.internal_server_error) }

	app.job_queue.invalidate(id)
	app.job_queue.insert_all(target) or { return app.status(.internal_server_error) }

	return app.json(.ok, new_data_response(target))
}
