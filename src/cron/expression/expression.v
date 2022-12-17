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
