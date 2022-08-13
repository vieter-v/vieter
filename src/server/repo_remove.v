module server

import web
import net.http
import web.response { new_response }

// delete_package tries to remove the given package.
['/:repo/:arch/:pkg'; delete]
fn (mut app App) delete_package(repo string, arch string, pkg string) web.Result {
	if !app.is_authorized() {
		return app.json(.unauthorized, new_response('Unauthorized.'))
	}

	res := app.repo.remove_pkg_from_arch_repo(repo, arch, pkg, true) or {
		app.lerror('Error while deleting package: $err.msg()')

		return app.json(http.Status.internal_server_error, new_response('Failed to delete package.'))
	}

	if res {
		app.linfo("Removed package '$pkg' from '$repo/$arch'")

		return app.json(http.Status.ok, new_response('Package removed.'))
	} else {
		app.linfo("Tried removing package '$pkg' from '$repo/$arch', but it doesn't exist.")

		return app.json(http.Status.not_found, new_response('Package not found.'))
	}
}

// delete_arch_repo tries to remove the given arch-repo.
['/:repo/:arch'; delete]
fn (mut app App) delete_arch_repo(repo string, arch string) web.Result {
	if !app.is_authorized() {
		return app.json(http.Status.unauthorized, new_response('Unauthorized.'))
	}

	res := app.repo.remove_arch_repo(repo, arch) or {
		app.lerror('Error while deleting arch-repo: $err.msg()')

		return app.json(http.Status.internal_server_error, new_response('Failed to delete arch-repo.'))
	}

	if res {
		app.linfo("Removed '$repo/$arch'")

		return app.json(http.Status.ok, new_response('Arch-repo removed.'))
	} else {
		app.linfo("Tried removing '$repo/$arch', but it doesn't exist.")

		return app.json(http.Status.not_found, new_response('Arch-repo not found.'))
	}
}

// delete_repo tries to remove the given repo.
['/:repo'; delete]
fn (mut app App) delete_repo(repo string) web.Result {
	if !app.is_authorized() {
		return app.json(http.Status.unauthorized, new_response('Unauthorized.'))
	}

	res := app.repo.remove_repo(repo) or {
		app.lerror('Error while deleting repo: $err.msg()')

		return app.json(http.Status.internal_server_error, new_response('Failed to delete repo.'))
	}

	if res {
		app.linfo("Removed '$repo'")

		return app.json(http.Status.ok, new_response('Repo removed.'))
	} else {
		app.linfo("Tried removing '$repo', but it doesn't exist.")

		return app.json(http.Status.not_found, new_response('Repo not found.'))
	}
}
