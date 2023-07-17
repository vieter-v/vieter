module web

// lfatal create a log message with the fatal level
pub fn (mut ctx Context) lfatal(msg string) {
	lock ctx.logger {
		ctx.logger.fatal(msg)
	}
}

// lerror create a log message with the error level
pub fn (mut ctx Context) lerror(msg string) {
	lock ctx.logger {
		ctx.logger.error(msg)
	}
}

// lwarn create a log message with the warn level
pub fn (mut ctx Context) lwarn(msg string) {
	lock ctx.logger {
		ctx.logger.warn(msg)
	}
}

// linfo create a log message with the info level
pub fn (mut ctx Context) linfo(msg string) {
	lock ctx.logger {
		ctx.logger.info(msg)
	}
}

// ldebug create a log message with the debug level
pub fn (mut ctx Context) ldebug(msg string) {
	lock ctx.logger {
		ctx.logger.debug(msg)
	}
}
