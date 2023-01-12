module cron

import time

// free the memory associated with the Expression.
[unsafe]
pub fn (ce &Expression) free() {
	C.vieter_cron_expr_free(ce)
}

// parse_expression parses a string into an Expression.
pub fn parse_expression(exp string) !&Expression {
	out := C.vieter_cron_expr_init()
	res := C.vieter_cron_expr_parse(out, exp.str)

	if res != .ok {
		return error(res.str())
	}

	return out
}

// next calculates the next occurence of the cron schedule, given a reference
// point.
pub fn (ce &Expression) next(ref time.Time) time.Time {
	st := SimpleTime{
		year: ref.year
		month: ref.month
		day: ref.day
		hour: ref.hour
		minute: ref.minute
	}

	out := SimpleTime{}
	C.vieter_cron_expr_next(&out, ce, &st)

	return time.new_time(time.Time{
		year: out.year
		month: out.month
		day: out.day
		hour: out.hour
		minute: out.minute
	})
}

// next_from_now calculates the next occurence of the cron schedule with the
// current time as reference.
pub fn (ce &Expression) next_from_now() time.Time {
	out := SimpleTime{}
	C.vieter_cron_expr_next_from_now(&out, ce)

	return time.new_time(time.Time{
		year: out.year
		month: out.month
		day: out.day
		hour: out.hour
		minute: out.minute
	})
}

// next_n returns the n next occurences of the expression, given a starting
// time.
pub fn (ce &Expression) next_n(ref time.Time, n int) []time.Time {
	mut times := []time.Time{cap: n}

	times << ce.next(ref)

	for i in 1 .. n {
		times << ce.next(times[i - 1])
	}

	return times
}
