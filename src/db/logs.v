module db

import time

pub struct BuildLog {
pub:
	id         int       [primary; sql: serial]
	repo_id    int       [nonull]
	start_time time.Time [nonull]
	end_time   time.Time [nonull]
	arch string [nonull]
	exit_code  int       [nonull]
}

// get_build_logs returns all BuildLog's in the database.
pub fn (db &VieterDb) get_build_logs() []BuildLog {
	res := sql db.conn {
		select from BuildLog order by id
	}

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
