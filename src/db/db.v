module db

import sqlite

struct VieterDb {
	conn sqlite.DB
}

// init initializes a database & adds the correct tables.
pub fn init(db_path string) ?VieterDb {
	conn := sqlite.connect(db_path) ?

	sql conn {
		create table GitRepo
	}

	return VieterDb{
		conn: conn
	}
}
