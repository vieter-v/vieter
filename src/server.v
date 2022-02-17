module main

import web
import os
import log
import repo

fn server() {
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

	// Configure web server
	key := os.getenv_opt('API_KEY') or { exit_with_message(1, 'No API key was provided.') }
	repo_dir := os.getenv_opt('REPO_DIR') or {
		exit_with_message(1, 'No repo directory was configured.')
	}
	pkg_dir := os.getenv_opt('PKG_DIR') or {
		exit_with_message(1, 'No package directory was configured.')
	}
	dl_dir := os.getenv_opt('DOWNLOAD_DIR') or {
		exit_with_message(1, 'No download directory was configured.')
	}

	// This also creates the directories if needed
	repo := repo.new(repo_dir, pkg_dir) or {
		logger.error(err.msg)
		exit(1)
	}

	os.mkdir_all(dl_dir) or { exit_with_message(1, 'Failed to create download directory.') }

	web.run(&App{
		logger: logger
		api_key: key
		dl_dir: dl_dir
		repo: repo
	}, port)
}
