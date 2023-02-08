module cron

fn test_not_allowed() {
	illegal_expressions := [
		'4 *-7',
		'4 *-7/4',
		'4 7/*',
		'0 0 30 2',
		'0 /5',
		'0  ',
		'0',
		'      0',
		'       0      ',
		'1 2 3 4~9',
		'1 1-3-5',
		'0 5/2-5',
		'',
		'1 1/2/3',
		'*5 8',
		'x 8',
	]

	mut res := false

	for exp in illegal_expressions {
		res = false
		parse_expression(exp) or { res = true }
		assert res, "'${exp}' should produce an error"
	}
}

fn test_auto_extend() ! {
	ce1 := parse_expression('5 5')!
	ce2 := parse_expression('5 5 *')!
	ce3 := parse_expression('5 5 * *')!

	assert ce1 == ce2 && ce2 == ce3
}

fn test_four() {
	parse_expression('0 1 2 3 ') or { assert false }
}
