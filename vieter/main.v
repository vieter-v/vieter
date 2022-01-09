module main

import vweb
import os
import log

const port = 8000

struct App {
	vweb.Context
	api_key  string [required; vweb_global]
	repo_dir string [required; vweb_global]
	logger   log.Log [required; vweb_global]
}

[noreturn]
fn exit_with_message(code int, msg string) {
	eprintln(msg)
	exit(code)
}

[post; '/publish']
fn (mut app App) put_package(filename string) vweb.Result {
	for _, files in app.files {
		for file in files {
			filepath := os.join_path_single(app.repo_dir, file.filename)

			if os.exists(filepath) {
				return app.text('File already exists.')
			}

			os.write_file(filepath, file.data) or {
				return app.text('Failed to upload file.')
			}

			return app.text('yeet')

		}
	}

	return app.text('done')
}

fn main() {
	// Configure logger
	log_level_str := os.getenv_opt('LOG_LEVEL') or { 'WARN' }
	log_level := log.level_from_tag(log_level_str) or {
		exit_with_message(1, 'Invalid log level. The allowed values are FATAL, ERROR, WARN, INFO & DEBUG.') }
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

	// Configure vweb server
	key := os.getenv_opt('API_KEY') or { exit_with_message(1, 'No API key was provided.') }
	repo_dir := os.getenv_opt('REPO_DIR') or {
		exit_with_message(1, 'No repo directory was configured.')
	}

	// We create the upload directory during startup
	if !os.is_dir(repo_dir) {
		os.mkdir_all(repo_dir) or { exit_with_message(2, "Failed to create repo directory '$repo_dir'.") }

		println("Repo directory '$repo_dir' created.")
	}

	vweb.run(&App{
		api_key: key,
		repo_dir: repo_dir,
		logger: logger
	}, port)
}
