module models

import time

pub struct BuildLog {
pub mut:
	id         int       [primary; sql: serial]
	repo_id    int       [nonull]
	start_time time.Time [nonull]
	end_time   time.Time [nonull]
	arch       string    [nonull]
	exit_code  int       [nonull]
}

// str returns a string representation.
pub fn (bl &BuildLog) str() string {
	mut parts := [
		'id: $bl.id',
		'repo id: $bl.repo_id',
		'start time: $bl.start_time.local()',
		'end time: $bl.end_time.local()',
		'duration: ${bl.end_time - bl.start_time}',
		'arch: $bl.arch',
		'exit code: $bl.exit_code',
	]
	str := parts.join('\n')

	return str
}

[params]
pub struct BuildLogFilter {
pub mut:
	limit      u64 = 25
	offset     u64
	repo       int
	before     time.Time
	after      time.Time
	arch       string
	exit_codes []string
}
