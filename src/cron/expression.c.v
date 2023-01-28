module cron

#flag -I @VMODROOT/libvieter/include
#flag -L @VMODROOT/libvieter/build
#flag -lvieter
#include "vieter_cron.h"

[typedef]
pub struct C.vieter_cron_expression {
	minutes      &u8
	hours        &u8
	days         &u8
	months       &u8
	minute_count u8
	hour_count   u8
	day_count    u8
	month_count  u8
}

pub type Expression = C.vieter_cron_expression

// == returns whether the two expressions are equal by value.
fn (ce1 Expression) == (ce2 Expression) bool {
	if ce1.month_count != ce2.month_count || ce1.day_count != ce2.day_count
		|| ce1.hour_count != ce2.hour_count || ce1.minute_count != ce2.minute_count {
		return false
	}

	for i in 0 .. ce1.month_count {
		unsafe {
			if ce1.months[i] != ce2.months[i] {
				return false
			}
		}
	}
	for i in 0 .. ce1.day_count {
		unsafe {
			if ce1.days[i] != ce2.days[i] {
				return false
			}
		}
	}
	for i in 0 .. ce1.hour_count {
		unsafe {
			if ce1.hours[i] != ce2.hours[i] {
				return false
			}
		}
	}
	for i in 0 .. ce1.minute_count {
		unsafe {
			if ce1.minutes[i] != ce2.minutes[i] {
				return false
			}
		}
	}

	return true
}

[typedef]
struct C.vieter_cron_simple_time {
	year   int
	month  int
	day    int
	hour   int
	minute int
}

type SimpleTime = C.vieter_cron_simple_time

enum ParseError as u8 {
	ok = 0
	invalid_expression = 1
	invalid_number = 2
	out_of_range = 3
	too_many_parts = 4
	not_enough_parts = 5
}

// str returns the string representation of a ParseError.
fn (e ParseError) str() string {
	return match e {
		.ok { '' }
		.invalid_expression { 'Invalid expression' }
		.invalid_number { 'Invalid number' }
		.out_of_range { 'Out of range' }
		.too_many_parts { 'Too many parts' }
		.not_enough_parts { 'Not enough parts' }
	}
}

fn C.vieter_cron_expr_init() &C.vieter_cron_expression

fn C.vieter_cron_expr_free(ce &C.vieter_cron_expression)

fn C.vieter_cron_expr_next(out &C.vieter_cron_simple_time, ce &C.vieter_cron_expression, ref &C.vieter_cron_simple_time)

fn C.vieter_cron_expr_next_from_now(out &C.vieter_cron_simple_time, ce &C.vieter_cron_expression)

fn C.vieter_cron_expr_parse(out &C.vieter_cron_expression, s &char) ParseError
