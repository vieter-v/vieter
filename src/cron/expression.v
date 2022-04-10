module cron

import math
import time

struct CronExpression {
	minutes []u32
	hours   []u32
	days    []u32
}

// next calculates the earliest time this cron expression is valid.
pub fn (ce &CronExpression) next(ref &time.Time) time.Time {
	res := time.Time{}

	mut day := 0
	mut hour := 0
	mut minute := 0

	// Find the next minute
	// If ref.minute is greater than 
	if ref.minute >= ce.minutes[ce.minutes.len - 1] || ref.minute < ce.minutes[0] {
		minute = ce.minutes[0]
	}else{
		for i in 0..ce.minutes.len {
			if ce.minutes[i] > ref.minute {
				minute = ce.minutes[i]
				break
			}
		}
	}

	return res
}

// parse_range parses a given string into a range of sorted integers, if
// possible.
fn parse_range(s string, min u32, max u32) ?[]u32 {
	mut out := []u32{}
	mut start := min
	mut interval := u32(1)

	if s != '*' {
		exps := s.split('/')

		start = math.min(max, math.max(exps[0].u32(), min))

		if exps.len > 1 {
			interval = exps[1].u32()
		}
		// Here, s solely consists of a number, so that's the only value we
		// should return.
		else {
			return [start]
		}
	}

	if interval == 0 {
		return []
	}

	for start <= max {
		out << start
		start += interval
	}

	return out
}

// min hour day month day-of-week
fn parse_expression(exp string) ?CronExpression {
	parts := exp.split(' ')

	if parts.len != 3 {
		return error('Expression must contain 5 space-separated parts.')
	}

	return CronExpression{
		minutes: parse_range(parts[0], 0, 59) ?
		hours: parse_range(parts[1], 0, 23) ?
		days: parse_range(parts[2], 0, 31) ?
	}
}
