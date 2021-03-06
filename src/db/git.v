module db

import models { GitRepo, GitRepoArch, GitRepoFilter }

// get_git_repos returns all GitRepo's in the database.
pub fn (db &VieterDb) get_git_repos(filter GitRepoFilter) []GitRepo {
	// This seems to currently be blocked by a bug in the ORM, I'll have to ask
	// around.
	if filter.repo != '' {
		res := sql db.conn {
			select from GitRepo where repo == filter.repo order by id limit filter.limit offset filter.offset
		}

		return res
	}

	res := sql db.conn {
		select from GitRepo order by id limit filter.limit offset filter.offset
	}

	return res
}

// get_git_repo tries to return a specific GitRepo.
pub fn (db &VieterDb) get_git_repo(repo_id int) ?GitRepo {
	res := sql db.conn {
		select from GitRepo where id == repo_id
	}

	// If a select statement fails, it returns a zeroed object. By
	// checking one of the required fields, we can see whether the query
	// returned a result or not.
	if res.id == 0 {
		return none
	}

	return res
}

// add_git_repo inserts the given GitRepo into the database.
pub fn (db &VieterDb) add_git_repo(repo GitRepo) {
	sql db.conn {
		insert repo into GitRepo
	}
}

// delete_git_repo deletes the repo with the given ID from the database.
pub fn (db &VieterDb) delete_git_repo(repo_id int) {
	sql db.conn {
		delete from GitRepo where id == repo_id
		delete from GitRepoArch where repo_id == repo_id
	}
}

// update_git_repo updates any non-array values for a given GitRepo.
pub fn (db &VieterDb) update_git_repo(repo_id int, params map[string]string) {
	mut values := []string{}

	// TODO does this allow for SQL injection?
	$for field in GitRepo.fields {
		if field.name in params {
			// Any fields that are array types require their own update method
			$if field.typ is string {
				values << "$field.name = '${params[field.name]}'"
			}
		}
	}
	values_str := values.join(', ')
	// I think this is actual SQL & not the ORM language
	query := 'update GitRepo set $values_str where id == $repo_id'

	db.conn.exec_none(query)
}

// update_git_repo_archs updates a given GitRepo's arch value.
pub fn (db &VieterDb) update_git_repo_archs(repo_id int, archs []GitRepoArch) {
	archs_with_id := archs.map(GitRepoArch{
		...it
		repo_id: repo_id
	})

	sql db.conn {
		delete from GitRepoArch where repo_id == repo_id
	}

	for arch in archs_with_id {
		sql db.conn {
			insert arch into GitRepoArch
		}
	}
}

// git_repo_exists is a utility function that checks whether a repo with the
// given id exists.
pub fn (db &VieterDb) git_repo_exists(repo_id int) bool {
	db.get_git_repo(repo_id) or { return false }

	return true
}
