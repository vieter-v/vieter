module expression

// parse_range_error returns the returned error message. If the result is '',
// that means the function didn't error.
fn parse_range_error(s string, min int, max int) string {
	mut bitv := []bool{len: max - min + 1, init: false}

	parse_range(s, min, max, mut bitv) or { return err.msg }

	return ''
}

// =====parse_range=====
fn test_range_star_range() ? {
	mut bitv := []bool{len: 6, init: false}
	parse_range('*', 0, 5, mut bitv) ?

	assert bitv == [true, true, true, true, true, true]
}

fn test_range_number() ? {
	mut bitv := []bool{len: 6, init: false}
	parse_range('4', 0, 5, mut bitv) ?

	assert bitv_to_ints(bitv, 0) == [4]
}

fn test_range_number_too_large() ? {
	assert parse_range_error('10', 0, 6) == 'Out of range.'
}

fn test_range_number_too_small() ? {
	assert parse_range_error('0', 2, 6) == 'Out of range.'
}

fn test_range_number_invalid() ? {
	assert parse_range_error('x', 0, 6) == 'Invalid number.'
}

fn test_range_step_star_1() ? {
	mut bitv := []bool{len: 21, init: false}
	parse_range('*/4', 0, 20, mut bitv) ?

	assert bitv_to_ints(bitv, 0) == [0, 4, 8, 12, 16, 20]
}

fn test_range_step_star_2() ? {
	mut bitv := []bool{len: 8, init: false}
	parse_range('*/3', 1, 8, mut bitv) ?

	assert bitv_to_ints(bitv, 1) == [1, 4, 7]
}

fn test_range_step_star_too_large() ? {
	assert parse_range_error('*/21', 0, 20) == 'Step size too large.'
}

fn test_range_step_zero() ? {
	assert parse_range_error('*/0', 0, 20) == 'Step size zero not allowed.'
}

fn test_range_step_number() ? {
	mut bitv := []bool{len: 21, init: false}
	parse_range('5/4', 2, 22, mut bitv) ?

	assert bitv_to_ints(bitv, 2) == [5, 9, 13, 17, 21]
}

fn test_range_step_number_too_large() ? {
	assert parse_range_error('10/4', 0, 5) == 'Out of range.'
}

fn test_range_step_number_too_small() ? {
	assert parse_range_error('2/4', 5, 10) == 'Out of range.'
}

fn test_range_dash() ? {
	mut bitv := []bool{len: 10, init: false}
	parse_range('4-8', 0, 9, mut bitv) ?

	assert bitv_to_ints(bitv, 0) == [4, 5, 6, 7, 8]
}

fn test_range_dash_step() ? {
	mut bitv := []bool{len: 10, init: false}
	parse_range('4-8/2', 0, 9, mut bitv) ?

	assert bitv_to_ints(bitv, 0) == [4, 6, 8]
}

// =====parse_part=====
fn test_part_single() ? {
	assert parse_part('*', 0, 5) ? == [0, 1, 2, 3, 4, 5]
}

fn test_part_multiple() ? {
	assert parse_part('*/2,2/3', 1, 8) ? == [1, 2, 3, 5, 7, 8]
}
