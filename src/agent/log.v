module agent

import log

// log a message with the given level
pub fn (mut d AgentDaemon) log(msg string, level log.Level) {
	lock d.logger {
		d.logger.send_output(msg, level)
	}
}

// lfatal create a log message with the fatal level
pub fn (mut d AgentDaemon) lfatal(msg string) {
	d.log(msg, log.Level.fatal)
}

// lerror create a log message with the error level
pub fn (mut d AgentDaemon) lerror(msg string) {
	d.log(msg, log.Level.error)
}

// lwarn create a log message with the warn level
pub fn (mut d AgentDaemon) lwarn(msg string) {
	d.log(msg, log.Level.warn)
}

// linfo create a log message with the info level
pub fn (mut d AgentDaemon) linfo(msg string) {
	d.log(msg, log.Level.info)
}

// ldebug create a log message with the debug level
pub fn (mut d AgentDaemon) ldebug(msg string) {
	d.log(msg, log.Level.debug)
}
