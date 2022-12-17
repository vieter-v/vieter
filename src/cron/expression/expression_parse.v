module expression

import bitfield

// parse_range parses a given string into a range of sorted integers. Its
// result is a BitField with set bits for all numbers in the result.
fn parse_range(s string, min int, max int) !bitfield.BitField {
	mut start := min
	mut end := max
	mut interval := 1
	mut bf := bitfield.new(max - min + 1)

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
		bf.set_bit(start - min)
		return bf
	}

	for start <= end {
		bf.set_bit(start - min)
		start += interval
	}

	return bf
}

// bf_to_ints takes a BitField and converts it into the expected list of actual
// integers.
fn bf_to_ints(bf bitfield.BitField, min int) []int {
	mut out := []int{}

	for i in 0 .. bf.get_size() {
		if bf.get_bit(i) == 1 {
			out << min + i
		}
	}

	return out
}

// parse_part parses a given part of a cron expression & returns the
// corresponding array of ints.
fn parse_part(s string, min int, max int) ![]int {
	mut bf := bitfield.new(max - min + 1)

	for range in s.split(',') {
		bf2 := parse_range(range, min, max)!
		bf = bitfield.bf_or(bf, bf2)
	}

	return bf_to_ints(bf, min)
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
