module server

import web

// delete_package tries to remove the given package.
['/:repo/:arch/:pkg'; auth; delete; markused]
fn (mut app App) delete_package(repo string, arch string, pkg string) web.Result {
	res := app.repo.remove_pkg_from_arch_repo(repo, arch, pkg, true) or {
		app.lerror('Error while deleting package: ${err.msg()}')

		return app.status(.internal_server_error)
	}

	if res {
		app.linfo("Removed package '${pkg}' from '${repo}/${arch}'")

		return app.status(.ok)
	} else {
		app.linfo("Tried removing package '${pkg}' from '${repo}/${arch}', but it doesn't exist.")

		return app.status(.not_found)
	}
}

// delete_arch_repo tries to remove the given arch-repo.
['/:repo/:arch'; auth; delete; markused]
fn (mut app App) delete_arch_repo(repo string, arch string) web.Result {
	res := app.repo.remove_arch_repo(repo, arch) or {
		app.lerror('Error while deleting arch-repo: ${err.msg()}')

		return app.status(.internal_server_error)
	}

	if res {
		app.linfo("Removed arch-repo '${repo}/${arch}'")

		return app.status(.ok)
	} else {
		app.linfo("Tried removing '${repo}/${arch}', but it doesn't exist.")

		return app.status(.not_found)
	}
}

// delete_repo tries to remove the given repo.
['/:repo'; auth; delete; markused]
fn (mut app App) delete_repo(repo string) web.Result {
	res := app.repo.remove_repo(repo) or {
		app.lerror('Error while deleting repo: ${err.msg()}')

		return app.status(.internal_server_error)
	}

	if res {
		app.linfo("Removed repo '${repo}'")

		return app.status(.ok)
	} else {
		app.linfo("Tried removing '${repo}', but it doesn't exist.")

		return app.status(.not_found)
	}
}
