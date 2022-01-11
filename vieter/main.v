module main

import web
import os
import log
import io
import repo

const port = 8000

const buf_size = 100_000

const db_name = 'pieter.db.tar.gz'

struct App {
	web.Context
	api_key  string [required; web_global]
	repo_dir string [required; web_global]
}

[noreturn]
fn exit_with_message(code int, msg string) {
	eprintln(msg)
	exit(code)
}

fn reader_to_file(mut reader io.BufferedReader, length int, path string) ? {
	// Open up a file for writing to
	mut file := os.create(path) ?
	defer {
		file.close()
	}

	mut buf := []byte{len: buf_size}
	mut bytes_left := length

	// Repeat as long as the stream still has data
	for bytes_left > 0 {
		// TODO check if just breaking here is safe
		bytes_read := reader.read(mut buf) or { break }
		bytes_left -= bytes_read

		mut to_write := bytes_read

		for to_write > 0 {
			// TODO don't just loop infinitely here
			bytes_written := file.write(buf[bytes_read - to_write..bytes_read]) or { continue }

			to_write = to_write - bytes_written
		}
	}
}

['/pkgs/:pkg'; put]
fn (mut app App) put_package(pkg string) web.Result {
	full_path := os.join_path_single(app.repo_dir, pkg)

	if os.exists(full_path) {
		app.lwarn("Tried to upload duplicate package '$pkg'")

		return app.text('File already exists.')
	}

	if length := app.req.header.get(.content_length) {
		reader_to_file(mut app.reader, length.int(), full_path) or {
			app.lwarn("Failed to upload package '$pkg'")

			return app.text('Failed to upload file.')
		}
	} else {
		app.lwarn("Tried to upload package '$pkg' without specifying a Content-Length.")
		return app.text("Content-Type header isn't set.")
	}

	repo.add_package(os.join_path_single(app.repo_dir, db_name), full_path) or {
		app.linfo("Failed to add package '$pkg' to database.")

		os.rm(full_path) or { println('Failed to remove $full_path') }

		return app.text('Failed to add package to repo.')
	}

	app.linfo("Uploaded package '$pkg'.")

	return app.text('Package added successfully.')
}

fn main() {
	// Configure logger
	log_level_str := os.getenv_opt('LOG_LEVEL') or { 'WARN' }
	log_level := log.level_from_tag(log_level_str) or {
		exit_with_message(1, 'Invalid log level. The allowed values are FATAL, ERROR, WARN, INFO & DEBUG.')
	}
	log_file := os.getenv_opt('LOG_FILE') or { 'vieter.log' }

	mut logger := log.Log{
		level: log_level
	}

	logger.set_full_logpath(log_file)
	logger.log_to_console_too()
	// logger.set
	logger.debug('Logger set up.')
	logger.flush()

	defer {
		logger.info('Flushing log file')
		logger.flush()
		logger.close()
	}

	// Configure web server
	key := os.getenv_opt('API_KEY') or { exit_with_message(1, 'No API key was provided.') }
	repo_dir := os.getenv_opt('REPO_DIR') or {
		exit_with_message(1, 'No repo directory was configured.')
	}

	// We create the upload directory during startup
	if !os.is_dir(repo_dir) {
		os.mkdir_all(repo_dir) or {
			exit_with_message(2, "Failed to create repo directory '$repo_dir'.")
		}

		println("Repo directory '$repo_dir' created.")
	}

	web.run(&App{
		api_key: key
		repo_dir: repo_dir
		logger: logger
	}, port)
}
