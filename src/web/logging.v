module web

import log

// log reate a log message with the given level
pub fn (mut ctx Context) log(msg &string, level log.Level) {
	lock ctx.logger {
		ctx.logger.send_output(msg, level)
	}
}

// lfatal create a log message with the fatal level
pub fn (mut ctx Context) lfatal(msg &string) {
	ctx.log(msg, log.Level.fatal)
}

// lerror create a log message with the error level
pub fn (mut ctx Context) lerror(msg &string) {
	ctx.log(msg, log.Level.error)
}

// lwarn create a log message with the warn level
pub fn (mut ctx Context) lwarn(msg &string) {
	ctx.log(msg, log.Level.warn)
}

// linfo create a log message with the info level
pub fn (mut ctx Context) linfo(msg &string) {
	ctx.log(msg, log.Level.info)
}

// ldebug create a log message with the debug level
pub fn (mut ctx Context) ldebug(msg &string) {
	ctx.log(msg, log.Level.debug)
}
