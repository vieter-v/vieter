module server

import web
import os
import repo
import time
import rand
import util
import web.response { new_data_response, new_response }

// healthcheck just returns a string, but can be used to quickly check if the
// server is still responsive.
['/health'; get; markused]
pub fn (mut app App) healthcheck() web.Result {
	return app.json(.ok, new_response('Healthy.'))
}

// get_repo_file handles all Pacman-related routes. It returns both the
// repository's archives, but also package archives or the contents of a
// package's desc file.
['/:repo/:arch/:filename'; get; head; markused]
fn (mut app App) get_repo_file(repo_ string, arch string, filename string) web.Result {
	mut full_path := ''

	db_exts := ['.db', '.files', '.db.tar.gz', '.files.tar.gz']

	// There's no point in having the ability to serve db archives with wrong
	// filenames
	if db_exts.any(filename == '${repo_}${it}') {
		full_path = os.join_path(app.repo.repos_dir, repo_, arch, filename)

		// repo-add does this using symlinks, but we just change the requested
		// path
		if !full_path.ends_with('.tar.gz') {
			full_path += '.tar.gz'
		}
	} else if filename.contains('.pkg') {
		full_path = os.join_path(app.repo.pkg_dir, repo_, arch, filename)
	}
	// Default behavior is to return the desc file for the package, if present.
	// This can then also be used by the build system to properly check whether
	// a package is present in an arch-repo.
	else {
		full_path = os.join_path(app.repo.repos_dir, repo_, arch, filename, 'desc')
	}

	return app.file(full_path)
}

// put_package handles publishing a package to a repository.
['/:repo/publish'; auth; markused; post]
fn (mut app App) put_package(repo_ string) web.Result {
	// api is a reserved keyword for api routes & should never be allowed to be
	// a repository.
	if repo_.to_lower() == 'api' {
		return app.json(.bad_request, new_response("'api' is a reserved keyword & cannot be used as a repository name."))
	}

	mut pkg_path := ''

	if length := app.req.header.get(.content_length) {
		// Generate a random filename for the temp file
		pkg_path = os.join_path_single(app.repo.pkg_dir, rand.uuid_v4())

		app.ldebug("Uploading ${length} bytes (${util.pretty_bytes(length.int())}) to '${pkg_path}'.")

		// This is used to time how long it takes to upload a file
		mut sw := time.new_stopwatch(time.StopWatchOptions{ auto_start: true })

		util.reader_to_file(mut app.reader, length.int(), pkg_path) or {
			app.lwarn("Failed to upload '${pkg_path}': ${err.msg()}")

			return app.status(.internal_server_error)
		}

		sw.stop()
		app.ldebug("Upload of '${pkg_path}' completed in ${sw.elapsed().seconds():.3}s.")
	} else {
		app.lwarn('Tried to upload package without specifying a Content-Length.')

		// length required
		return app.status(.length_required)
	}

	res := app.repo.add_pkg_from_path(repo_, pkg_path) or {
		app.lerror('Error while adding package: ${err.msg()}')

		os.rm(pkg_path) or { app.lerror("Failed to remove download '${pkg_path}': ${err.msg()}") }

		return app.status(.internal_server_error)
	}

	app.linfo("Added '${res.name}-${res.version}' to '${repo_} (${res.archs.join(',')})'.")

	return app.json(.ok, new_data_response(res))
}
