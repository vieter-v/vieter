module main

import web
import os
import repo

['/pkgs/:pkg'; put]
fn (mut app App) put_package(pkg string) web.Result {
	full_path := os.join_path_single(app.repo_dir, pkg)

	if os.exists(full_path) {
		app.lwarn("Tried to upload duplicate package '$pkg'")

		return app.text('File already exists.')
	}

	if length := app.req.header.get(.content_length) {
		app.ldebug("Uploading $length bytes to package '$pkg'")
		reader_to_file(mut app.reader, length.int(), full_path) or {
			app.lwarn("Failed to upload package '$pkg'")

			return app.text('Failed to upload file.')
		}
	} else {
		app.lwarn("Tried to upload package '$pkg' without specifying a Content-Length.")
		return app.text("Content-Type header isn't set.")
	}

	lock app.repo {
		app.repo.add_package(full_path) or {
			app.linfo("Failed to add package '$pkg' to database.")

			os.rm(full_path) or { println('Failed to remove $full_path') }

			return app.text('Failed to add package to repo.')
		}

		app.linfo("Added '$pkg' to repository.")
	}

	app.linfo("Uploaded package '$pkg'.")

	return app.text('Package added successfully.')
}
