module cron

// =====parse_range=====
fn test_parse_star_range() ? {
	assert parse_range('*', 0, 5) ? == [u32(0), 1, 2, 3, 4, 5]
}

fn test_parse_number() ? {
	assert parse_range('4', 0, 5) ? == [u32(4)]
}

fn test_parse_number_too_large() ? {
	assert parse_range('10', 0, 6) ? == [u32(6)]
}

fn test_parse_number_too_small() ? {
	assert parse_range('0', 2, 6) ? == [u32(2)]
}

fn test_parse_step_star() ? {
	assert parse_range('*/4', 0, 20) ? == [u32(0), 4, 8, 12, 16, 20]
}

fn test_parse_step_star_too_large() ? {
	assert parse_range('*/21', 0, 20) ? == [u32(0)]
}

fn test_parse_step_zero() ? {
	assert parse_range('*/0', 0, 20) ? == []
}

fn test_parse_step_number() ? {
	assert parse_range('5/4', 0, 20) ? == [u32(5), 9, 13, 17]
}

fn test_parse_step_number_too_large() ? {
	assert parse_range('10/4', 0, 5) ? == [u32(5)]
}

fn test_parse_step_number_too_small() ? {
	assert parse_range('2/4', 5, 10) ? == [u32(5), 9]
}


