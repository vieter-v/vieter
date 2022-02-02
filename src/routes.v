module main

import web
import os
import repo
import time
import rand

const prefixes = ['B', 'KB', 'MB', 'GB']

// pretty_bytes converts a byte count to human-readable version
fn pretty_bytes(bytes int) string {
	mut i := 0
	mut n := f32(bytes)

	for n >= 1024 {
		i++
		n /= 1024
	}

	return '${n:.2}${prefixes[i]}'
}

fn is_pkg_name(s string) bool {
	return s.contains('.pkg')
}

// healthcheck just returns a string, but can be used to quickly check if the
// server is still responsive.
['/health'; get]
pub fn (mut app App) healthcheck() web.Result {
	return app.text('Healthy')
}

// get_root handles a GET request for a file on the root
['/:filename'; get]
fn (mut app App) get_root(filename string) web.Result {
	mut full_path := ''

	if filename.ends_with('.db') || filename.ends_with('.files') {
		full_path = os.join_path_single(app.repo.repo_dir, '${filename}.tar.gz')
	} else if filename.ends_with('.db.tar.gz') || filename.ends_with('.files.tar.gz') {
		full_path = os.join_path_single(app.repo.repo_dir, '$filename')
	} else {
		full_path = os.join_path_single(app.repo.pkg_dir, filename)
	}

	return app.file(full_path)
}

['/publish'; post]
fn (mut app App) put_package() web.Result {
	if !app.is_authorized() {
		return app.text('Unauthorized.')
	}

	mut pkg_path := ''

	if length := app.req.header.get(.content_length) {
		// Generate a random filename for the temp file
		pkg_path = os.join_path_single(app.dl_dir, rand.uuid_v4())

		for os.exists(pkg_path) {
			pkg_path = os.join_path_single(app.dl_dir, rand.uuid_v4())
		}

		app.ldebug("Uploading $length bytes (${pretty_bytes(length.int())}) to '$pkg_path'.")

		// This is used to time how long it takes to upload a file
		mut sw := time.new_stopwatch(time.StopWatchOptions{ auto_start: true })

		reader_to_file(mut app.reader, length.int(), pkg_path) or {
			app.lwarn("Failed to upload '$pkg_path'")

			return app.text('Failed to upload file.')
		}

		sw.stop()
		app.ldebug("Upload of '$pkg_path' completed in ${sw.elapsed().seconds():.3}s.")
	} else {
		app.lwarn('Tried to upload package without specifying a Content-Length.')
		return app.text("Content-Type header isn't set.")
	}

	res := app.repo.add_from_path(pkg_path) or {
		app.lerror('Error while adding package: $err.msg')

		os.rm(pkg_path) or { app.lerror("Failed to remove download '$pkg_path': $err.msg") }

		return app.text('Failed to add package.')
	}
	if !res.added {
		os.rm(pkg_path) or { app.lerror("Failed to remove download '$pkg_path': $err.msg") }

		app.lwarn("Duplicate package '$res.pkg.full_name()'.")

		return app.text('File already exists.')
	}

	app.linfo("Added '$res.pkg.full_name()' to repository.")

	return app.text('Package added successfully.')
}
