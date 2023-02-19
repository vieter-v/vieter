module dbms

import db.sqlite
import time

pub struct VieterDb {
	conn sqlite.DB
}

struct MigrationVersion {
	id      int [primary]
	version int
}

const (
	migrations_up   = [
		$embed_file('migrations/001-initial/up.sql'),
		$embed_file('migrations/002-rename-to-targets/up.sql'),
		$embed_file('migrations/003-target-url-type/up.sql'),
		$embed_file('migrations/004-nullable-branch/up.sql'),
		$embed_file('migrations/005-repo-path/up.sql'),
	]
	migrations_down = [
		$embed_file('migrations/001-initial/down.sql'),
		$embed_file('migrations/002-rename-to-targets/down.sql'),
		$embed_file('migrations/003-target-url-type/down.sql'),
		$embed_file('migrations/004-nullable-branch/down.sql'),
		$embed_file('migrations/005-repo-path/down.sql'),
	]
)

// init initializes a database & adds the correct tables.
pub fn init(db_path string) !VieterDb {
	conn := sqlite.connect(db_path)!

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
	for i in cur_version.version .. dbms.migrations_up.len {
		migration := dbms.migrations_up[i].to_string()

		version_num := i + 1

		// vfmt does not like these dots
		println('Applying migration ${version_num}' + '...')

		// The sqlite library seems to not like it when multiple statements are
		// passed in a single exec. Therefore, we split them & run them all
		// separately.
		for part in migration.split(';').map(it.trim_space()).filter(it != '') {
			res := conn.exec_none(part)

			if res != sqlite.sqlite_done {
				return error('An error occurred while applying migration ${version_num}: SQLite error code ${res}')
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

// row_into[T] converts an sqlite.Row into a given type T by parsing each field
// from a string according to its type.
pub fn row_into[T](row sqlite.Row) T {
	mut i := 0
	mut out := T{}

	$for field in T.fields {
		$if field.typ is string {
			out.$(field.name) = row.vals[i]
		} $else $if field.typ is int {
			out.$(field.name) = row.vals[i].int()
		} $else $if field.typ is time.Time {
			out.$(field.name) = time.unix(row.vals[i].int())
		}

		i += 1
	}
	return out
}
