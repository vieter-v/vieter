module main

import web
import os
import repo
import time

const prefixes = ['B', 'KB', 'MB', 'GB']

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

['/:filename'; get]
fn (mut app App) get_root(filename string) web.Result {
	mut full_path := ''

	if is_pkg_name(filename) {
		full_path = os.join_path_single(app.repo.pkg_dir, filename)
	} else {
		full_path = os.join_path_single(app.repo.repo_dir, filename)
	}

	return app.file(full_path)
}

// ['/pkgs/:pkg'; put]
// fn (mut app App) put_package(pkg string) web.Result {
// 	if !app.is_authorized() {
// 		return app.text('Unauthorized.')
// 	}

// 	if !is_pkg_name(pkg) {
// 		app.lwarn("Invalid package name '$pkg'.")

// 		return app.text('Invalid filename.')
// 	}

// 	if app.repo.exists(pkg) {
// 		app.lwarn("Duplicate package '$pkg'")

// 		return app.text('File already exists.')
// 	}

// 	pkg_path := app.repo.pkg_path(pkg)

// 	if length := app.req.header.get(.content_length) {
// 		app.ldebug("Uploading $length (${pretty_bytes(length.int())}) bytes to package '$pkg'.")

// 		// This is used to time how long it takes to upload a file
// 		mut sw := time.new_stopwatch(time.StopWatchOptions{ auto_start: true })

// 		reader_to_file(mut app.reader, length.int(), pkg_path) or {
// 			app.lwarn("Failed to upload package '$pkg'")

// 			return app.text('Failed to upload file.')
// 		}

// 		sw.stop()
// 		app.ldebug("Upload of package '$pkg' completed in ${sw.elapsed().seconds():.3}s.")
// 	} else {
// 		app.lwarn("Tried to upload package '$pkg' without specifying a Content-Length.")
// 		return app.text("Content-Type header isn't set.")
// 	}

// 	app.repo.add_package(pkg_path) or {
// 		app.lwarn("Failed to add package '$pkg' to database.")

// 		os.rm(pkg_path) or { println('Failed to remove $pkg_path') }

// 		return app.text('Failed to add package to repo.')
// 	}

// 	app.linfo("Added '$pkg' to repository.")

// 	return app.text('Package added successfully.')
// }

['/add'; put]
pub fn (mut app App) add_package() web.Result {
	return app.text('')
}
