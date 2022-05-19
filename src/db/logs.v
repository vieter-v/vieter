module db

import models { BuildLog, BuildLogFilter }
import time

// get_build_logs returns all BuildLog's in the database.
pub fn (db &VieterDb) get_build_logs(filter BuildLogFilter) []BuildLog {
	mut where_parts := []string{}

	if filter.repo != 0 {
		where_parts << 'repo_id == $filter.repo'
	}

	if filter.before != time.Time{} {
		where_parts << 'start_time < $filter.before.unix_time()'
	}

	if filter.after != time.Time{} {
		where_parts << 'start_time < $filter.after.unix_time()'
	}

	where_str := if where_parts.len > 0 {
		' where ' + where_parts.map('($it)').join(' and ')
	} else {
		''
	}

	query := 'select from BuildLog' + where_str
	res := db.conn.exec(query)

/* 	res := sql db.conn { */
/* 		select from BuildLog where filter.repo == 0 || repo_id == filter.repo order by id */
/* 	} */

	return res
}

// get_build_logs_for_repo returns all BuildLog's in the database for a given
// repo.
pub fn (db &VieterDb) get_build_logs_for_repo(repo_id int) []BuildLog {
	res := sql db.conn {
		select from BuildLog where repo_id == repo_id order by id
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
pub fn (db &VieterDb) add_build_log(log BuildLog) {
	sql db.conn {
		insert log into BuildLog
	}
}

// delete_build_log delete the BuildLog with the given ID from the database.
pub fn (db &VieterDb) delete_build_log(id int) {
	sql db.conn {
		delete from BuildLog where id == id
	}
}
