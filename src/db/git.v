module db

pub struct GitRepoArch {
pub:
	id      int    [primary; sql: serial]
	repo_id int    [nonull]
	value   string [nonull]
}

// str returns a string representation.
pub fn (gra &GitRepoArch) str() string {
	return gra.value
}

pub struct GitRepo {
pub mut:
	id int [optional; primary; sql: serial]
	// URL of the Git repository
	url string [nonull]
	// Branch of the Git repository to use
	branch string [nonull]
	// Which repo the builder should publish packages to
	repo string [nonull]
	// Cron schedule describing how frequently to build the repo.
	schedule string [optional]
	// On which architectures the package is allowed to be built. In reality,
	// this controls which builders will periodically build the image.
	arch []GitRepoArch [fkey: 'repo_id']
}

// str returns a string representation.
pub fn (gr &GitRepo) str() string {
	mut parts := [
		'id: $gr.id',
		'url: $gr.url',
		'branch: $gr.branch',
		'repo: $gr.repo',
		'schedule: $gr.schedule',
		'arch: ${gr.arch.map(it.value).join(', ')}',
	]
	str := parts.join('\n')

	return str
}

// patch_from_params patches a GitRepo from a map[string]string, usually
// provided from a web.App's params
pub fn (mut r GitRepo) patch_from_params(params map[string]string) {
	$for field in GitRepo.fields {
		if field.name in params {
			$if field.typ is string {
				r.$(field.name) = params[field.name]
				// This specific type check is needed for the compiler to ensure
				// our types are correct
			} $else $if field.typ is []GitRepoArch {
				r.$(field.name) = params[field.name].split(',').map(GitRepoArch{ value: it })
			}
		}
	}
}

// git_repo_from_params creates a GitRepo from a map[string]string, usually
// provided from a web.App's params
pub fn git_repo_from_params(params map[string]string) ?GitRepo {
	mut repo := GitRepo{}

	// If we're creating a new GitRepo, we want all fields to be present before
	// "patching".
	$for field in GitRepo.fields {
		if field.name !in params && !field.attrs.contains('optional') {
			return error('Missing parameter: ${field.name}.')
		}
	}
	repo.patch_from_params(params)

	return repo
}

// get_git_repos returns all GitRepo's in the database.
pub fn (db &VieterDb) get_git_repos() []GitRepo {
	res := sql db.conn {
		select from GitRepo order by id
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
	if res.url == '' {
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
	// sql db.conn {
	//	update GitRepo set repo
	//}
	mut values := []string{}

	$for field in GitRepo.fields {
		if field.name in params {
			// Any fields that are array types require their own update method
			$if field.typ is string {
				values << "$field.name = '${params[field.name]}'"
			}
		}
	}
	values_str := values.join(', ')
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
