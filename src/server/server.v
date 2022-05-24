module server

import web
import os
import log
import repo
import util
import db

const (
	port          = 8000
	log_file_name = 'vieter.log'
	repo_dir_name = 'repos'
	db_file_name  = 'vieter.sqlite'
	logs_dir_name = 'logs'
)

struct App {
	web.Context
pub:
	conf Config [required; web_global]
pub mut:
	repo repo.RepoGroupManager [required; web_global]
	db   db.VieterDb
}

// server starts the web server & starts listening for requests
pub fn server(conf Config) ? {
	// Prevent using 'any' as the default arch
	if conf.default_arch == 'any' {
		util.exit_with_message(1, "'any' is not allowed as the value for default_arch.")
	}

	// Configure logger
	log_level := log.level_from_tag(conf.log_level) or {
		util.exit_with_message(1, 'Invalid log level. The allowed values are FATAL, ERROR, WARN, INFO & DEBUG.')
	}

	os.mkdir_all(conf.data_dir) or { util.exit_with_message(1, 'Failed to create data directory.') }

	logs_dir := os.join_path_single(conf.data_dir, server.logs_dir_name)

	if !os.exists(logs_dir) {
		os.mkdir(os.join_path_single(conf.data_dir, server.logs_dir_name)) or {
			util.exit_with_message(1, 'Failed to create logs directory.')
		}
	}

	mut logger := log.Log{
		level: log_level
	}

	log_file := os.join_path_single(conf.data_dir, server.log_file_name)
	logger.set_full_logpath(log_file)
	logger.log_to_console_too()

	defer {
		logger.info('Flushing log file')
		logger.flush()
		logger.close()
	}

	repo_dir := os.join_path_single(conf.data_dir, server.repo_dir_name)
	// This also creates the directories if needed
	repo := repo.new(repo_dir, conf.pkg_dir, conf.default_arch) or {
		logger.error(err.msg())
		exit(1)
	}

	db_file := os.join_path_single(conf.data_dir, server.db_file_name)
	db := db.init(db_file) or {
		util.exit_with_message(1, 'Failed to initialize database: $err.msg()')
	}

	web.run(&App{
		logger: logger
		conf: conf
		repo: repo
		db: db
	}, server.port)
}
