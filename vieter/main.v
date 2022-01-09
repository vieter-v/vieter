module main

import web
import os
import log
import io

const port = 8000
const buf_size = 1_000_000

struct App {
	web.Context
	api_key  string  [required; web_global]
	repo_dir string  [required; web_global]
	logger   log.Log [required; web_global]
}

[noreturn]
fn exit_with_message(code int, msg string) {
	eprintln(msg)
	exit(code)
}

fn reader_to_file(mut reader io.BufferedReader, path string) ? {
	// Open up a file for writing to
	mut file := os.create(path) ?
	defer {
		file.close()
	}

	mut buf := []byte{len: buf_size}

	// Repeat as long as the stream still has data
	for {
		// TODO don't just endlessly loop if reading keeps failing
		println('heey')
		// TODO check if just breaking here is safe
		bytes_read := reader.read(mut &buf) or {
			println('youre here')
			break
		}
		println(bytes_read)

		mut to_write := bytes_read

		for to_write > 0 {
			// TODO don't just loop infinitely here
			bytes_written := file.write(buf[bytes_read - to_write..bytes_read]) or {
				println("$err.msg")
				continue
			}
			println(bytes_written)

			to_write = to_write - bytes_written
		}
	}

	println('File complete!')
}

[put; '/pkgs/:pkg']
fn (mut app App) put_package(pkg string) web.Result {
	full_path := os.join_path_single(app.repo_dir, pkg)

	if os.exists(full_path) {
		return app.text('File already exists.')
	}

	reader_to_file(mut app.reader, full_path) or {
		return app.text('Failed to upload file.')
	}

	return app.text('just stop')
}

// ['/publish'; post]
// fn (mut app App) put_package(filename string) web.Result {
// 	for _, files in app.files {
// 		for file in files {
// 			filepath := os.join_path_single(app.repo_dir, file.filename)

// 			if os.exists(filepath) {
// 				return app.text('File already exists.')
// 			}

// 			os.write_file(filepath, file.data) or { return app.text('Failed to upload file.') }

// 			return app.text('yeet')
// 		}
// 	}

// 	return app.text('done')
// }

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
	defer {
		logger.info('Flushing log file')
		logger.flush()
		logger.close()
	}
	// logger.set
	logger.info('Logger set up.')
	logger.flush()

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
