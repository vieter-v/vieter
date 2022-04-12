module cron

import time { new_time, Time, parse }

fn test_next_simple() ? {
	ce := parse_expression('0 3') ?
	t := parse('2002-01-01 00:00:00') ?
	t2 := ce.next(t) ?

	assert t2.year == 2002
	assert t2.month == 1
	assert t2.day == 1
	assert t2.hour == 3
	assert t2.minute == 0
}

fn test_next_identical() ? {
	ce := parse_expression('0 3') ?
	t := parse('2002-01-01 03:00:00') ?
	t2 := ce.next(t) ?

	assert t2.year == 2002
	assert t2.month == 1
	assert t2.day == 2
	assert t2.hour == 3
	assert t2.minute == 0
}

fn test_next_next_day() ? {
	ce := parse_expression('0 3') ?
	t := parse('2002-01-01 04:00:00') ?
	t2 := ce.next(t) ?

	assert t2.year == 2002
	assert t2.month == 1
	assert t2.day == 2
	assert t2.hour == 3
	assert t2.minute == 0
}
