module cron

import time { parse }

fn util_test_time(exp string, t1_str string, t2_str string) ? {
	ce := parse_expression(exp) ?
	t1 := parse(t1_str) ?
	t2 := parse(t2_str) ?

	t3 := ce.next(t1) ?

	assert t2.year == t3.year
	assert t2.month == t3.month
	assert t2.day == t3.day
	assert t2.hour == t3.hour
	assert t2.minute == t3.minute
}

fn test_next_simple() ? {
	// Very simple
	util_test_time('0 3', '2002-01-01 00:00:00', '2002-01-01 03:00:00') ?

	// Overlap to next day
	util_test_time('0 3', '2002-01-01 03:00:00', '2002-01-02 03:00:00') ?
	util_test_time('0 3', '2002-01-01 04:00:00', '2002-01-02 03:00:00') ?

	util_test_time('0 3/4', '2002-01-01 04:00:00', '2002-01-01 07:00:00') ?
}
