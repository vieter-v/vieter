module server

import web
import os
import repo
import time
import rand
import util
import net.http

// healthcheck just returns a string, but can be used to quickly check if the
// server is still responsive.
['/health'; get]
pub fn (mut app App) healthcheck() web.Result {
	return app.text('Healthy')
}

['/:repo/:arch/:filename'; get; head]
fn (mut app App) get_repo_file(repo string, arch string, filename string) web.Result {
	mut full_path := ''

	db_exts := ['.db', '.files', '.db.tar.gz', '.files.tar.gz']

	if db_exts.any(filename.ends_with(it)) {
		full_path = os.join_path(app.repo.data_dir, repo, arch, filename)

		// repo-add does this using symlinks, but we just change the requested
		// path
		if !full_path.ends_with('.tar.gz') {
			full_path += '.tar.gz'
		}
	} else {
		full_path = os.join_path_single(app.repo.pkg_dir, filename)
	}

	// Scuffed way to respond to HEAD requests
	if app.req.method == http.Method.head {
		if os.exists(full_path) {
			return app.ok('')
		}

		return app.not_found()
	}

	return app.file(full_path)
}

['/:repo/publish'; post]
fn (mut app App) put_package(repo string) web.Result {
	if !app.is_authorized() {
		return app.text('Unauthorized.')
	}

	mut pkg_path := ''

	if length := app.req.header.get(.content_length) {
		// Generate a random filename for the temp file
		pkg_path = os.join_path_single(app.conf.download_dir, rand.uuid_v4())

		for os.exists(pkg_path) {
			pkg_path = os.join_path_single(app.conf.download_dir, rand.uuid_v4())
		}

		app.ldebug("Uploading $length bytes (${util.pretty_bytes(length.int())}) to '$pkg_path'.")

		// This is used to time how long it takes to upload a file
		mut sw := time.new_stopwatch(time.StopWatchOptions{ auto_start: true })

		util.reader_to_file(mut app.reader, length.int(), pkg_path) or {
			app.lwarn("Failed to upload '$pkg_path'")

			return app.text('Failed to upload file.')
		}

		sw.stop()
		app.ldebug("Upload of '$pkg_path' completed in ${sw.elapsed().seconds():.3}s.")
	} else {
		app.lwarn('Tried to upload package without specifying a Content-Length.')
		return app.text("Content-Type header isn't set.")
	}

	res := app.repo.add_pkg_from_path(repo, pkg_path) or {
		app.lerror('Error while adding package: $err.msg')

		os.rm(pkg_path) or { app.lerror("Failed to remove download '$pkg_path': $err.msg") }

		return app.text('Failed to add package.')
	}

	if !res.added {
		os.rm(pkg_path) or { app.lerror("Failed to remove download '$pkg_path': $err.msg") }

		app.lwarn("Duplicate package '$res.pkg.full_name()' in repo '$repo ($res.pkg.info.arch)'.")

		return app.text('File already exists.')
	}

	app.linfo("Added '$res.pkg.full_name()' to repo '$repo ($res.pkg.info.arch)'.")

	return app.text('Package added successfully.')
}
