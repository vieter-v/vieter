module server

import web
import net.http
import response { new_data_response, new_response }
import db
import models { GitRepo, GitRepoArch, GitRepoFilter }

// v1_get_repos returns the current list of repos.
['/api/v1/repos'; get]
fn (mut app App) v1_get_repos() web.Result {
	if !app.is_authorized() {
		return app.json(http.Status.unauthorized, new_response('Unauthorized.'))
	}

	filter := models.from_params<GitRepoFilter>(app.query) or {
		return app.json(http.Status.bad_request, new_response('Invalid query parameters.'))
	}
	repos := app.db.get_git_repos(filter)

	return app.json(http.Status.ok, new_data_response(repos))
}

// v1_get_single_repo returns the information for a single repo.
['/api/v1/repos/:id'; get]
fn (mut app App) v1_get_single_repo(id int) web.Result {
	if !app.is_authorized() {
		return app.json(http.Status.unauthorized, new_response('Unauthorized.'))
	}

	repo := app.db.get_git_repo(id) or { return app.not_found() }

	return app.json(http.Status.ok, new_data_response(repo))
}

// v1_post_repo creates a new repo from the provided query string.
['/api/v1/repos'; post]
fn (mut app App) v1_post_repo() web.Result {
	if !app.is_authorized() {
		return app.json(http.Status.unauthorized, new_response('Unauthorized.'))
	}

	mut params := app.query.clone()

	// If a repo is created without specifying the arch, we assume it's meant
	// for the default architecture.
	if 'arch' !in params {
		params['arch'] = app.conf.default_arch
	}

	new_repo := models.from_params<GitRepo>(params) or {
		return app.json(http.Status.bad_request, new_response(err.msg()))
	}

	app.db.add_git_repo(new_repo)

	return app.json(http.Status.ok, new_response('Repo added successfully.'))
}

// v1_delete_repo removes a given repo from the server's list.
['/api/v1/repos/:id'; delete]
fn (mut app App) v1_delete_repo(id int) web.Result {
	if !app.is_authorized() {
		return app.json(http.Status.unauthorized, new_response('Unauthorized.'))
	}

	app.db.delete_git_repo(id)

	return app.json(http.Status.ok, new_response('Repo removed successfully.'))
}

// v1_patch_repo updates a repo's data with the given query params.
['/api/v1/repos/:id'; patch]
fn (mut app App) v1_patch_repo(id int) web.Result {
	if !app.is_authorized() {
		return app.json(http.Status.unauthorized, new_response('Unauthorized.'))
	}

	app.db.update_git_repo(id, app.query)

	if 'arch' in app.query {
		arch_objs := app.query['arch'].split(',').map(GitRepoArch{ value: it })

		app.db.update_git_repo_archs(id, arch_objs)
	}

	return app.json(http.Status.ok, new_response('Repo updated successfully.'))
}
