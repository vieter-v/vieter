module db

import models { Target, TargetArch, TargetFilter }

// get_targets returns all targets in the database.
pub fn (db &VieterDb) get_targets(filter TargetFilter) []Target {
	// This seems to currently be blocked by a bug in the ORM, I'll have to ask
	// around.
	if filter.repo != '' {
		res := sql db.conn {
			select from Target where repo == filter.repo order by id limit filter.limit offset filter.offset
		}

		return res
	}

	res := sql db.conn {
		select from Target order by id limit filter.limit offset filter.offset
	}

	return res
}

// get_target tries to return a specific target.
pub fn (db &VieterDb) get_target(target_id int) ?Target {
	res := sql db.conn {
		select from Target where id == target_id
	}

	// If a select statement fails, it returns a zeroed object. By
	// checking one of the required fields, we can see whether the query
	// returned a result or not.
	if res.id == 0 {
		return none
	}

	return res
}

// add_target inserts the given target into the database.
pub fn (db &VieterDb) add_target(target Target) int {
	sql db.conn {
		insert target into Target
	}

	// ID of inserted target is the largest id
	inserted_target := sql db.conn {
		select from Target order by id desc limit 1
	}

	return inserted_target.id
}

// delete_target deletes the target with the given id from the database.
pub fn (db &VieterDb) delete_target(target_id int) {
	sql db.conn {
		delete from Target where id == target_id
		delete from TargetArch where target_id == target_id
	}
}

// update_target updates any non-array values for a given target.
pub fn (db &VieterDb) update_target(target_id int, params map[string]string) {
	mut values := []string{}

	// TODO does this allow for SQL injection?
	$for field in Target.fields {
		if field.name in params {
			// Any fields that are array types require their own update method
			$if field.typ is string {
				values << "$field.name = '${params[field.name]}'"
			}
		}
	}
	values_str := values.join(', ')
	// I think this is actual SQL & not the ORM language
	query := 'update Target set $values_str where id == $target_id'

	db.conn.exec_none(query)
}

// update_target_archs updates a given target's arch value.
pub fn (db &VieterDb) update_target_archs(target_id int, archs []TargetArch) {
	archs_with_id := archs.map(TargetArch{
		...it
		target_id: target_id
	})

	sql db.conn {
		delete from TargetArch where target_id == target_id
	}

	for arch in archs_with_id {
		sql db.conn {
			insert arch into TargetArch
		}
	}
}

// target_exists is a utility function that checks whether a target with the
// given id exists.
pub fn (db &VieterDb) target_exists(target_id int) bool {
	db.get_target(target_id) or { return false }

	return true
}
