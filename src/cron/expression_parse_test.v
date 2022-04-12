module cron

// parse_range_error returns the returned error message. If the result is '',
// that means the function didn't error.
fn parse_range_error(s string, min int, max int) string {
	mut bitv := []bool{init: false, len: max - min + 1}

	parse_range(s, min, max, mut bitv) or {
		return err.msg
	}

	return ''
}

// =====parse_range=====
fn test_parse_star_range() ? {
	mut bitv := []bool{init: false, len: 6}
	parse_range('*', 0, 5, mut bitv) ?

	assert bitv == [true, true, true, true, true, true]
}

fn test_parse_number() ? {
	mut bitv := []bool{init: false, len: 6}
	parse_range('4', 0, 5, mut bitv) ?

	assert bitv_to_ints(bitv, 0) == [4]
}

fn test_parse_number_too_large() ? {
	assert parse_range_error('10', 0, 6) == 'Out of range.'
}

fn test_parse_number_too_small() ? {
	assert parse_range_error('0', 2, 6) == 'Out of range.'
}

fn test_parse_step_star() ? {
	mut bitv := []bool{init: false, len: 21}
	parse_range('*/4', 0, 20, mut bitv) ?

	assert bitv_to_ints(bitv, 0) == [0, 4, 8, 12, 16, 20]
}

fn test_parse_step_star_too_large() ? {
	assert parse_range_error('*/21', 0, 20) == 'Step too large.'
}

fn test_parse_step_zero() ? {
	assert parse_range_error('*/0', 0, 20) == 'Step size zero not allowed.'
}

fn test_parse_step_number() ? {
	mut bitv := []bool{init: false, len: 21}
	parse_range('5/4', 0, 20, mut bitv) ?
	assert bitv_to_ints(bitv, 0) == [5, 9, 13, 17]
}

fn test_parse_step_number_too_large() ? {
	assert parse_range_error('10/4', 0, 5) == 'Out of range.'
}

fn test_parse_step_number_too_small() ? {
	assert parse_range_error('2/4', 5, 10) == 'Out of range.'
}
