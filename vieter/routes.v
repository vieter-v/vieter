module main

import web
import os
import repo

['/pkgs/:pkg'; put]
fn (mut app App) put_package(pkg string) web.Result {
	if app.repo.exists(pkg) {
		app.lwarn("Tried to upload duplicate package '$pkg'")

		return app.text('File already exists.')
	}

	pkg_path := app.repo.pkg_path(pkg)

	if length := app.req.header.get(.content_length) {
		app.ldebug("Uploading $length bytes to package '$pkg'")
		println(pkg_path)
		reader_to_file(mut app.reader, length.int(), pkg_path) or {
			app.lwarn("Failed to upload package '$pkg'")

			return app.text('Failed to upload file.')
		}
	} else {
		app.lwarn("Tried to upload package '$pkg' without specifying a Content-Length.")
		return app.text("Content-Type header isn't set.")
	}

	app.repo.add_package(pkg_path) or {
		app.linfo("Failed to add package '$pkg' to database.")

		os.rm(pkg_path) or { println('Failed to remove $pkg_path') }

		return app.text('Failed to add package to repo.')
	}

	app.linfo("Added '$pkg' to repository.")
	app.linfo("Uploaded package '$pkg'.")

	return app.text('Package added successfully.')
}
