module server

import web
import net.http
import response { new_data_response, new_response }
import db
import models { Target, TargetArch, TargetFilter }

// v1_get_targets returns the current list of targets.
['/api/v1/targets'; get]
fn (mut app App) v1_get_targets() web.Result {
	if !app.is_authorized() {
		return app.json(http.Status.unauthorized, new_response('Unauthorized.'))
	}

	filter := models.from_params<TargetFilter>(app.query) or {
		return app.json(http.Status.bad_request, new_response('Invalid query parameters.'))
	}
	repos := app.db.get_targets(filter)

	return app.json(http.Status.ok, new_data_response(repos))
}

// v1_get_single_target returns the information for a single target.
['/api/v1/targets/:id'; get]
fn (mut app App) v1_get_single_target(id int) web.Result {
	if !app.is_authorized() {
		return app.json(http.Status.unauthorized, new_response('Unauthorized.'))
	}

	repo := app.db.get_target(id) or { return app.not_found() }

	return app.json(http.Status.ok, new_data_response(repo))
}

// v1_post_target creates a new target from the provided query string.
['/api/v1/targets'; post]
fn (mut app App) v1_post_target() web.Result {
	if !app.is_authorized() {
		return app.json(http.Status.unauthorized, new_response('Unauthorized.'))
	}

	mut params := app.query.clone()

	// If a repo is created without specifying the arch, we assume it's meant
	// for the default architecture.
	if 'arch' !in params {
		params['arch'] = app.conf.default_arch
	}

	new_repo := models.from_params<Target>(params) or {
		return app.json(http.Status.bad_request, new_response(err.msg()))
	}

	// Ensure someone doesn't submit an invalid kind
	if new_repo.kind !in models.valid_kinds {
		return app.json(http.Status.bad_request, new_response('Invalid kind.'))
	}

	app.db.add_target(new_repo)

	return app.json(http.Status.ok, new_response('Repo added successfully.'))
}

// v1_delete_target removes a given target from the server's list.
['/api/v1/targets/:id'; delete]
fn (mut app App) v1_delete_target(id int) web.Result {
	if !app.is_authorized() {
		return app.json(http.Status.unauthorized, new_response('Unauthorized.'))
	}

	app.db.delete_target(id)

	return app.json(http.Status.ok, new_response('Repo removed successfully.'))
}

// v1_patch_target updates a target's data with the given query params.
['/api/v1/targets/:id'; patch]
fn (mut app App) v1_patch_target(id int) web.Result {
	if !app.is_authorized() {
		return app.json(http.Status.unauthorized, new_response('Unauthorized.'))
	}

	app.db.update_target(id, app.query)

	if 'arch' in app.query {
		arch_objs := app.query['arch'].split(',').map(TargetArch{ value: it })

		app.db.update_target_archs(id, arch_objs)
	}

	return app.json(http.Status.ok, new_response('Repo updated successfully.'))
}
