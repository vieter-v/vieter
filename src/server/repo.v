module server

import web
import os
import repo
import time
import rand
import util
import net.http
import web.response { new_response }

// healthcheck just returns a string, but can be used to quickly check if the
// server is still responsive.
['/health'; get]
pub fn (mut app App) healthcheck() web.Result {
	return app.json(.ok, new_response('Healthy.'))
}

// get_repo_file handles all Pacman-related routes. It returns both the
// repository's archives, but also package archives or the contents of a
// package's desc file.
['/:repo/:arch/:filename'; get; head]
fn (mut app App) get_repo_file(repo string, arch string, filename string) web.Result {
	mut full_path := ''

	db_exts := ['.db', '.files', '.db.tar.gz', '.files.tar.gz']

	// There's no point in having the ability to serve db archives with wrong
	// filenames
	if db_exts.any(filename == '$repo$it') {
		full_path = os.join_path(app.repo.repos_dir, repo, arch, filename)

		// repo-add does this using symlinks, but we just change the requested
		// path
		if !full_path.ends_with('.tar.gz') {
			full_path += '.tar.gz'
		}
	} else if filename.contains('.pkg') {
		full_path = os.join_path(app.repo.pkg_dir, repo, arch, filename)
	}
	// Default behavior is to return the desc file for the package, if present.
	// This can then also be used by the build system to properly check whether
	// a package is present in an arch-repo.
	else {
		full_path = os.join_path(app.repo.repos_dir, repo, arch, filename, 'desc')
	}

	return app.file(full_path)
}

// put_package handles publishing a package to a repository.
['/:repo/publish'; post]
fn (mut app App) put_package(repo string) web.Result {
	if !app.is_authorized() {
		return app.json(http.Status.unauthorized, new_response('Unauthorized.'))
	}

	mut pkg_path := ''

	if length := app.req.header.get(.content_length) {
		// Generate a random filename for the temp file
		pkg_path = os.join_path_single(app.repo.pkg_dir, rand.uuid_v4())

		app.ldebug("Uploading $length bytes (${util.pretty_bytes(length.int())}) to '$pkg_path'.")

		// This is used to time how long it takes to upload a file
		mut sw := time.new_stopwatch(time.StopWatchOptions{ auto_start: true })

		util.reader_to_file(mut app.reader, length.int(), pkg_path) or {
			app.lwarn("Failed to upload '$pkg_path'")

			return app.json(http.Status.internal_server_error, new_response('Failed to upload file.'))
		}

		sw.stop()
		app.ldebug("Upload of '$pkg_path' completed in ${sw.elapsed().seconds():.3}s.")
	} else {
		app.lwarn('Tried to upload package without specifying a Content-Length.')

		// length required
		return app.status(http.Status.length_required)
	}

	res := app.repo.add_pkg_from_path(repo, pkg_path) or {
		app.lerror('Error while adding package: $err.msg()')

		os.rm(pkg_path) or { app.lerror("Failed to remove download '$pkg_path': $err.msg()") }

		return app.json(http.Status.internal_server_error, new_response('Failed to add package.'))
	}

	if !res.added {
		os.rm(pkg_path) or { app.lerror("Failed to remove download '$pkg_path': $err.msg()") }

		app.lwarn("Duplicate package '$res.pkg.full_name()' in repo '$repo'.")

		return app.json(http.Status.bad_request, new_response('File already exists.'))
	}

	app.linfo("Added '$res.pkg.full_name()' to repo '$repo ($res.pkg.info.arch)'.")

	return app.json(http.Status.ok, new_response('Package added successfully.'))
}
