module cron

fn test_parse_star_range() ? {
	assert parse_range('*', 0, 5) ? == [u32(0), 1, 2, 3, 4, 5]
}

fn test_parse_number() ? {
	assert parse_range('4', 0, 5) ? == [u32(4)]
}
