module web

import log

pub fn (mut ctx Context) log(msg &string, level log.Level) {
	lock ctx.logger {
		ctx.logger.send_output(msg, level)
	}
}

pub fn (mut ctx Context) lfatal(msg &string) {
	ctx.log(msg, log.Level.fatal)
}

pub fn (mut ctx Context) lerror(msg &string) {
	ctx.log(msg, log.Level.error)
}

pub fn (mut ctx Context) lwarn(msg &string) {
	ctx.log(msg, log.Level.warn)
}

pub fn (mut ctx Context) linfo(msg &string) {
	ctx.log(msg, log.Level.info)
}

pub fn (mut ctx Context) ldebug(msg &string) {
	ctx.log(msg, log.Level.debug)
}
