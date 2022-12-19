module models

import time
import os

pub struct BuildLog {
pub mut:
	id         int       [primary; sql: serial]
	target_id  int       [nonull]
	start_time time.Time [nonull]
	end_time   time.Time [nonull]
	arch       string    [nonull]
	exit_code  int       [nonull]
}

// str returns a string representation.
pub fn (bl &BuildLog) str() string {
	mut parts := [
		'id: $bl.id',
		'target id: $bl.target_id',
		'start time: $bl.start_time.local()',
		'end time: $bl.end_time.local()',
		'duration: ${bl.end_time - bl.start_time}',
		'arch: $bl.arch',
		'exit code: $bl.exit_code',
	]
	str := parts.join('\n')

	return str
}

// path returns the path to the log file, relative to the logs directory
pub fn (bl &BuildLog) path() string {
	filename := bl.start_time.custom_format('YYYY-MM-DD_HH-mm-ss')

	return os.join_path(bl.target_id.str(), bl.arch, filename)
}

[params]
pub struct BuildLogFilter {
pub mut:
	limit      u64 = 25
	offset     u64
	target     int
	before     time.Time
	after      time.Time
	arch       string
	exit_codes []string
}
