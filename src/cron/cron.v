module cron

import log
import cron.daemon
import cron.expression

// cron starts a cron daemon & starts periodically scheduling builds.
pub fn cron(conf Config) ? {
	// Configure logger
	log_level := log.level_from_tag(conf.log_level) or {
		return error('Invalid log level. The allowed values are FATAL, ERROR, WARN, INFO & DEBUG.')
	}

	mut logger := log.Log{
		level: log_level
	}

	logger.set_full_logpath(conf.log_file)
	logger.log_to_console_too()

	ce := expression.parse_expression(conf.global_schedule) or {
		return error('Error while parsing global cron expression: $err.msg()')
	}

	mut d := daemon.init_daemon(logger, conf.address, conf.api_key, conf.base_image, ce,
		conf.max_concurrent_builds, conf.api_update_frequency, conf.image_rebuild_frequency) ?

	d.run() ?
}
