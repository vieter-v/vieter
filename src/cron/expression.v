module cron

import math
import time

const days_in_month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

struct CronExpression {
	minutes []int
	hours   []int
	days    []int
	months  []int
}

// next calculates the earliest time this cron expression is valid.
pub fn (ce &CronExpression) next(ref time.Time) ?time.Time {
	mut minute_index := 0
	mut hour_index := 0
	mut day_index := 0
	mut month_index := 0

	for month_index < ce.months.len && ref.month > ce.months[month_index] {
		month_index++
	}

	if month_index < ce.months.len {
		for day_index < ce.days.len && ref.day > ce.days[day_index] {
			day_index++
		}

		if day_index < ce.days.len {
			for hour_index < ce.hours.len && ref.hour > ce.hours[hour_index] {
				hour_index++
			}

			if hour_index < ce.hours.len {
				// For each unit, we calculate what the next value is
				for minute_index < ce.minutes.len && ref.minute >= ce.minutes[minute_index] {
					minute_index++
				}
			}
		}
	}


	// Sometime we have to shift values one more
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

	mut reset := false

	// If the day can't be planned in the current month, we go to the next one
	// and go back to day one
	if day > days_in_month[ce.months[month_index % ce.months.len] - 1] {
		month_index += 1
		day = ce.days[0]

		// Make sure we only plan in a month that the day occurs in
		for day > days_in_month[ce.months[month_index & ce.months.len] - 1] {
			month_index += 1

			// Prevent scenario where there are no months that can be scheduled.
			if month_index == 2 * ce.months.len {
				return error('No schedulable moment.')
			}
		}
	}


	month := ce.months[month_index % ce.months.len]
	mut year := ref.year

	if month_index >= ce.months.len {
		year++
	}

	return time.Time{
		year: year
		month: month
		day: day
		minute: minute
		hour: hour
	}
}

fn (ce &CronExpression) next_from_now() ?time.Time {
	return ce.next(time.now())
}

// parse_range parses a given string into a range of sorted integers, if
// possible.
fn parse_range(s string, min int, max int) ?[]int {
	mut out := []int{}
	mut start := min
	mut interval := 1

	if s != '*' {
		exps := s.split('/')

		start = math.min(max, math.max(exps[0].int(), min))

		if exps.len > 1 {
			interval = exps[1].int()
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
	mut parts := exp.split(' ')

	if parts.len < 2 || parts.len > 4 {
		return error('Expression must contain between 2 and 4 space-separated parts.')
	}

	// For ease of use, we allow the user to only specify as many parts as they
	// need.
	for parts.len < 4 {
		parts << '*'
	}

	return CronExpression{
		minutes: parse_range(parts[0], 0, 59) ?
		hours: parse_range(parts[1], 0, 23) ?
		days: parse_range(parts[2], 1, 31) ?
		months: parse_range(parts[3], 1, 12) ?
	}
}
