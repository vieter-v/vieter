module cron

import git
import time
import log
import util
import cron.daemon

// cron starts a cron daemon & starts periodically scheduling builds.
pub fn cron(conf Config) ? {
	// Configure logger
	log_level := log.level_from_tag(conf.log_level) or {
		util.exit_with_message(1, 'Invalid log level. The allowed values are FATAL, ERROR, WARN, INFO & DEBUG.')
	}

	mut logger := log.Log{
		level: log_level
	}

	logger.set_full_logpath(conf.log_file)
	logger.log_to_console_too()

	d := daemon.init(conf)
}
