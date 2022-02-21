module server

import web
import os
import log
import repo
import env
import util

const port = 8000

struct App {
	web.Context
pub:
	conf env.ServerConfig [required; web_global]
pub mut:
	repo repo.Repo [required; web_global]
	// This is used to claim the file lock on the repos file
	git_mutex shared util.Dummy
}

pub fn server() ? {
	conf := env.load<env.ServerConfig>() ?

	// Configure logger
	log_level := log.level_from_tag(conf.log_level) or {
		util.exit_with_message(1, 'Invalid log level. The allowed values are FATAL, ERROR, WARN, INFO & DEBUG.')
	}

	mut logger := log.Log{
		level: log_level
	}

	logger.set_full_logpath(conf.log_file)
	logger.log_to_console_too()

	defer {
		logger.info('Flushing log file')
		logger.flush()
		logger.close()
	}

	// This also creates the directories if needed
	repo := repo.new(conf.repo_dir, conf.pkg_dir) or {
		logger.error(err.msg)
		exit(1)
	}

	os.mkdir_all(conf.download_dir) or {
		util.exit_with_message(1, 'Failed to create download directory.')
	}

	web.run(&App{
		logger: logger
		conf: conf
		repo: repo
	}, server.port)
}
