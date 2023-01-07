module daemon

// lfatal create a log message with the fatal level
pub fn (mut d Daemon) lfatal(msg string) {
	lock d.logger {
		d.logger.fatal(msg)
	}
}

// lerror create a log message with the error level
pub fn (mut d Daemon) lerror(msg string) {
	lock d.logger {
		d.logger.error(msg)
	}
}

// lwarn create a log message with the warn level
pub fn (mut d Daemon) lwarn(msg string) {
	lock d.logger {
		d.logger.warn(msg)
	}
}

// linfo create a log message with the info level
pub fn (mut d Daemon) linfo(msg string) {
	lock d.logger {
		d.logger.info(msg)
	}
}

// ldebug create a log message with the debug level
pub fn (mut d Daemon) ldebug(msg string) {
	lock d.logger {
		d.logger.debug(msg)
	}
}
