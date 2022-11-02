module expression

import time

pub struct CronExpression {
	minutes []int
	hours   []int
	days    []int
	months  []int
}

// next calculates the earliest time this cron expression is valid. It will
// always pick a moment in the future, even if ref matches completely up to the
// minute. This function conciously does not take gap years into account.
pub fn (ce &CronExpression) next(ref time.Time) !time.Time {
	// If the given ref matches the next cron occurence up to the minute, it
	// will return that value. Because we always want to return a value in the
	// future, we artifically shift the ref 60 seconds to make sure we always
	// match in the future. A shift of 60 seconds is enough because the cron
	// expression does not allow for accuracy smaller than one minute.
	sref := ref

	// For all of these values, the rule is the following: if their value is
	// the length of their respective array in the CronExpression object, that
	// means we've looped back around. This means that the "bigger" value has
	// to be incremented by one. For example, if the minutes have looped
	// around, that means that the hour has to be incremented as well.
	mut minute_index := 0
	mut hour_index := 0
	mut day_index := 0
	mut month_index := 0

	// This chain is the same logic multiple times, namely that if a "bigger"
	// value loops around, then the smaller value will always reset as well.
	// For example, if we're going to a new day, the hour & minute will always
	// be their smallest value again.
	for month_index < ce.months.len && sref.month > ce.months[month_index] {
		month_index++
	}

	if month_index < ce.months.len && sref.month == ce.months[month_index] {
		for day_index < ce.days.len && sref.day > ce.days[day_index] {
			day_index++
		}

		if day_index < ce.days.len && ce.days[day_index] == sref.day {
			for hour_index < ce.hours.len && sref.hour > ce.hours[hour_index] {
				hour_index++
			}

			if hour_index < ce.hours.len && ce.hours[hour_index] == sref.hour {
				// Minute is the only value where we explicitely make sure we
				// can't match sref's value exactly. This is to ensure we only
				// return values in the future.
				for minute_index < ce.minutes.len && sref.minute >= ce.minutes[minute_index] {
					minute_index++
				}
			}
		}
	}

	// Here, we increment the "bigger" values by one if the smaller ones loop
	// around. The order is important, as it allows a sort-of waterfall effect
	// to occur which updates all values if required.
	if minute_index == ce.minutes.len && hour_index < ce.hours.len {
		hour_index += 1
	}

	if hour_index == ce.hours.len && day_index < ce.days.len {
		day_index += 1
	}

	if day_index == ce.days.len && month_index < ce.months.len {
		month_index += 1
	}

	mut minute := ce.minutes[minute_index % ce.minutes.len]
	mut hour := ce.hours[hour_index % ce.hours.len]
	mut day := ce.days[day_index % ce.days.len]

	// Sometimes, we end up with a day that does not exist within the selected
	// month, e.g. day 30 in February. When this occurs, we reset day back to
	// the smallest value & loop over to the next month that does have this
	// day.
	if day > time.month_days[ce.months[month_index % ce.months.len] - 1] {
		day = ce.days[0]
		month_index += 1

		for day > time.month_days[ce.months[month_index & ce.months.len] - 1] {
			month_index += 1

			// If for whatever reason the day value ends up being something
			// that can't be scheduled in any month, we have to make sure we
			// don't create an infinite loop.
			if month_index == 2 * ce.months.len {
				return error('No schedulable moment.')
			}
		}
	}

	month := ce.months[month_index % ce.months.len]
	mut year := sref.year

	// If the month loops over, we need to increment the year.
	if month_index >= ce.months.len {
		year++
	}

	return time.new_time(time.Time{
		year: year
		month: month
		day: day
		minute: minute
		hour: hour
	})
}

// next_from_now returns the result of ce.next(ref) where ref is the result of
// time.now().
pub fn (ce &CronExpression) next_from_now() !time.Time {
	return ce.next(time.now())
}

// next_n returns the n next occurences of the expression, given a starting
// time.
pub fn (ce &CronExpression) next_n(ref time.Time, n int) ![]time.Time {
	mut times := []time.Time{cap: n}

	times << ce.next(ref)!

	for i in 1 .. n {
		times << ce.next(times[i - 1])!
	}

	return times
}

// parse_range parses a given string into a range of sorted integers, if
// possible.
fn parse_range(s string, min int, max int, mut bitv []bool) ! {
	mut start := min
	mut end := max
	mut interval := 1

	exps := s.split('/')

	if exps.len > 2 {
		return error('Invalid expression.')
	}

	if exps[0] != '*' {
		dash_parts := exps[0].split('-')

		if dash_parts.len > 2 {
			return error('Invalid expression.')
		}

		start = dash_parts[0].int()

		// The builtin parsing functions return zero if the string can't be
		// parsed into a number, so we have to explicitely check whether they
		// actually entered zero or if it's an invalid number.
		if start == 0 && dash_parts[0] != '0' {
			return error('Invalid number.')
		}

		// Check whether the start value is out of range
		if start < min || start > max {
			return error('Out of range.')
		}

		if dash_parts.len == 2 {
			end = dash_parts[1].int()

			if end == 0 && dash_parts[1] != '0' {
				return error('Invalid number.')
			}

			if end < start || end > max {
				return error('Out of range.')
			}
		}
	}

	if exps.len > 1 {
		interval = exps[1].int()

		// interval being zero is always invalid, but we want to check why
		// it's invalid for better error messages.
		if interval == 0 {
			if exps[1] != '0' {
				return error('Invalid number.')
			} else {
				return error('Step size zero not allowed.')
			}
		}

		if interval > max - min {
			return error('Step size too large.')
		}
	}
	// Here, s solely consists of a number, so that's the only value we
	// should return.
	else if exps[0] != '*' && !exps[0].contains('-') {
		bitv[start - min] = true
		return
	}

	for start <= end {
		bitv[start - min] = true
		start += interval
	}
}

// bitv_to_ints converts a bit vector into an array containing the
// corresponding values.
fn bitv_to_ints(bitv []bool, min int) []int {
	mut out := []int{}

	for i in 0 .. bitv.len {
		if bitv[i] {
			out << min + i
		}
	}

	return out
}

// parse_part parses a given part of a cron expression & returns the
// corresponding array of ints.
fn parse_part(s string, min int, max int) ![]int {
	mut bitv := []bool{len: max - min + 1, init: false}

	for range in s.split(',') {
		parse_range(range, min, max, mut bitv)!
	}

	return bitv_to_ints(bitv, min)
}

// parse_expression parses an entire cron expression string into a
// CronExpression object, if possible.
pub fn parse_expression(exp string) !CronExpression {
	// The filter allows for multiple spaces between parts
	mut parts := exp.split(' ').filter(it != '')

	if parts.len < 2 || parts.len > 4 {
		return error('Expression must contain between 2 and 4 space-separated parts.')
	}

	// For ease of use, we allow the user to only specify as many parts as they
	// need.
	for parts.len < 4 {
		parts << '*'
	}

	mut part_results := [][]int{}

	mins := [0, 0, 1, 1]
	maxs := [59, 23, 31, 12]

	// This for loop allows us to more clearly propagate the error to the user.
	for i, min in mins {
		part_results << parse_part(parts[i], min, maxs[i]) or {
			return error('An error occurred with part $i: $err.msg()')
		}
	}

	return CronExpression{
		minutes: part_results[0]
		hours: part_results[1]
		days: part_results[2]
		months: part_results[3]
	}
}
