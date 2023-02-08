module server

import web
import os
import log
import repo
import util
import dbms
import build { BuildJobQueue }
import cron
import metrics

const (
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
	// Keys are the various architectures for packages
	job_queue BuildJobQueue [required; web_global]
	db        dbms.VieterDb
}

// init_job_queue populates a fresh job queue with all the targets currently
// stored in the database.
fn (mut app App) init_job_queue() ! {
	for target in app.db.targets(limit: 0) {
		app.job_queue.insert_all(target)!
	}
}

// server starts the web server & starts listening for requests
pub fn server(conf Config) ! {
	// Prevent using 'any' as the default arch
	if conf.default_arch == 'any' {
		util.exit_with_message(1, "'any' is not allowed as the value for default_arch.")
	}

	global_ce := cron.parse_expression(conf.global_schedule) or {
		util.exit_with_message(1, 'Invalid global cron expression: ${err.msg()}')
	}

	log_removal_ce := cron.parse_expression(conf.log_removal_schedule) or {
		util.exit_with_message(1, 'Invalid log removal cron expression: ${err.msg()}')
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
	db := dbms.init(db_file) or {
		util.exit_with_message(1, 'Failed to initialize database: ${err.msg()}')
	}

	mut collector := if conf.collect_metrics {
		&metrics.MetricsCollector(metrics.new_default_collector())
	} else {
		&metrics.MetricsCollector(metrics.new_null_collector())
	}

	collector.histogram_buckets_set('http_requests_duration_seconds', [0.001, 0.005, 0.01, 0.05,
		0.1, 0.5, 1, 5, 10])

	mut app := &App{
		logger: logger
		api_key: conf.api_key
		conf: conf
		repo: repo
		db: db
		collector: collector
		job_queue: build.new_job_queue(global_ce, conf.base_image)
	}
	app.init_job_queue() or {
		util.exit_with_message(1, 'Failed to inialize job queue: ${err.msg()}')
	}

	if conf.max_log_age > 0 {
		spawn app.log_removal_daemon(log_removal_ce)
	}

	web.run(app, conf.port)
}
