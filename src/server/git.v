module server

import web
import net.http
import response { new_data_response, new_response }
import db

// get_repos returns the current list of repos.
['/api/repos'; get]
fn (mut app App) get_repos() web.Result {
	if !app.is_authorized() {
		return app.json(http.Status.unauthorized, new_response('Unauthorized.'))
	}

	filter := db.filter_from_params<db.GitRepoFilter>(app.query) or {
		return app.json(http.Status.bad_request, new_response('Invalid query parameters.'))
	}
	repos := app.db.get_git_repos(filter)

	return app.json(http.Status.ok, new_data_response(repos))
}

// get_single_repo returns the information for a single repo.
['/api/repos/:id'; get]
fn (mut app App) get_single_repo(id int) web.Result {
	if !app.is_authorized() {
		return app.json(http.Status.unauthorized, new_response('Unauthorized.'))
	}

	repo := app.db.get_git_repo(id) or { return app.not_found() }

	return app.json(http.Status.ok, new_data_response(repo))
}

// post_repo creates a new repo from the provided query string.
['/api/repos'; post]
fn (mut app App) post_repo() web.Result {
	if !app.is_authorized() {
		return app.json(http.Status.unauthorized, new_response('Unauthorized.'))
	}

	mut params := app.query.clone()

	// If a repo is created without specifying the arch, we assume it's meant
	// for the default architecture.
	if 'arch' !in params {
		params['arch'] = app.conf.default_arch
	}

	new_repo := db.git_repo_from_params(params) or {
		return app.json(http.Status.bad_request, new_response(err.msg()))
	}

	app.db.add_git_repo(new_repo)

	return app.json(http.Status.ok, new_response('Repo added successfully.'))
}

// delete_repo removes a given repo from the server's list.
['/api/repos/:id'; delete]
fn (mut app App) delete_repo(id int) web.Result {
	if !app.is_authorized() {
		return app.json(http.Status.unauthorized, new_response('Unauthorized.'))
	}

	app.db.delete_git_repo(id)

	return app.json(http.Status.ok, new_response('Repo removed successfully.'))
}

// patch_repo updates a repo's data with the given query params.
['/api/repos/:id'; patch]
fn (mut app App) patch_repo(id int) web.Result {
	if !app.is_authorized() {
		return app.json(http.Status.unauthorized, new_response('Unauthorized.'))
	}

	app.db.update_git_repo(id, app.query)

	if 'arch' in app.query {
		arch_objs := app.query['arch'].split(',').map(db.GitRepoArch{ value: it })

		app.db.update_git_repo_archs(id, arch_objs)
	}

	return app.json(http.Status.ok, new_response('Repo updated successfully.'))
}
