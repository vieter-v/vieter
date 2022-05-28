module db

import sqlite

struct VieterDb {
	conn sqlite.DB
}

struct MigrationVersion {
	id      int [primary]
	version int
}

const (
	migrations_up   = [$embed_file('migrations/001-initial/up.sql')]
	migrations_down = [$embed_file('migrations/001-initial/down.sql')]
)

// init initializes a database & adds the correct tables.
pub fn init(db_path string) ?VieterDb {
	conn := sqlite.connect(db_path)?

	sql conn {
		create table MigrationVersion
	}

	cur_version := sql conn {
		select from MigrationVersion limit 1
	}

	// If there's no row yet, we add it here
	if cur_version == MigrationVersion{} {
		sql conn {
			insert cur_version into MigrationVersion
		}
	}

	// Apply each migration in order
	for i in cur_version.version .. db.migrations_up.len {
		migration := db.migrations_up[i].to_string()

		version_num := i + 1

		// vfmt does not like these dots
		println('Applying migration $version_num' + '...')

		// The sqlite library seems to not like it when multiple statements are
		// passed in a single exec. Therefore, we split them & run them all
		// separately.
		for part in migration.split(';').map(it.trim_space()).filter(it != '') {
			res := conn.exec_none(part)

			if res != sqlite.sqlite_done {
				return error('An error occurred while applying migration $version_num')
			}
		}

		// The where clause doesn't really matter, as there will always only be
		// one entry anyways.
		sql conn {
			update MigrationVersion set version = version_num where id > 0
		}
	}

	return VieterDb{
		conn: conn
	}
}
