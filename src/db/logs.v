module db

import models { BuildLog, BuildLogFilter }
import time

// get_build_logs returns all BuildLog's in the database.
pub fn (db &VieterDb) get_build_logs(filter BuildLogFilter) []BuildLog {
	mut where_parts := []string{}

	if filter.target != 0 {
		where_parts << 'target_id == $filter.target'
	}

	if filter.before != time.Time{} {
		where_parts << 'start_time < $filter.before.unix_time()'
	}

	if filter.after != time.Time{} {
		where_parts << 'start_time > $filter.after.unix_time()'
	}

	// NOTE: possible SQL injection
	if filter.arch != '' {
		where_parts << "arch == '$filter.arch'"
	}

	mut parts := []string{}

	for exp in filter.exit_codes {
		if exp[0] == `!` {
			code := exp[1..].int()

			parts << 'exit_code != $code'
		} else {
			code := exp.int()

			parts << 'exit_code == $code'
		}
	}

	if parts.len > 0 {
		where_parts << parts.map('($it)').join(' or ')
	}

	mut where_str := ''

	if where_parts.len > 0 {
		where_str = 'where ' + where_parts.map('($it)').join(' and ')
	}

	query := 'select * from BuildLog $where_str limit $filter.limit offset $filter.offset'
	rows, _ := db.conn.exec(query)
	res := rows.map(row_into<BuildLog>(it))

	return res
}

// get_build_logs_for_target returns all BuildLog's in the database for a given
// target.
pub fn (db &VieterDb) get_build_logs_for_target(target_id int) []BuildLog {
	res := sql db.conn {
		select from BuildLog where target_id == target_id order by id
	}

	return res
}

// get_build_log tries to return a specific BuildLog.
pub fn (db &VieterDb) get_build_log(id int) ?BuildLog {
	res := sql db.conn {
		select from BuildLog where id == id
	}

	if res.id == 0 {
		return none
	}

	return res
}

// add_build_log inserts the given BuildLog into the database.
pub fn (db &VieterDb) add_build_log(log BuildLog) int {
	sql db.conn {
		insert log into BuildLog
	}

	inserted_id := db.conn.last_id() as int

	return inserted_id
}

// delete_build_log delete the BuildLog with the given ID from the database.
pub fn (db &VieterDb) delete_build_log(id int) {
	sql db.conn {
		delete from BuildLog where id == id
	}
}
