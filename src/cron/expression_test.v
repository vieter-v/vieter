module cron

fn test_parse_star_range() {
	assert parse_range('*', 0, 5) == [0, 1, 2, 3, 4, 5]
}
