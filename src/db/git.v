module db

struct GitRepoArch {
pub:
	id      int    [primary; sql: serial]
	repo_id int
	value   string
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

// repo_from_params creates a GitRepo from a map[string]string, usually
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

pub fn (db &VieterDb) get_git_repos() []GitRepo {
	res := sql db.conn {
		select from GitRepo
	}

	return res
}

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

pub fn (db &VieterDb) add_git_repo(repo GitRepo) {
	sql db.conn {
		insert repo into GitRepo
	}
}

pub fn (db &VieterDb) delete_git_repo(repo_id int) {
	sql db.conn {
		delete from GitRepo where id == repo_id
	}
}

pub fn (db &VieterDb) update_git_repo(repo GitRepo) {
	/* sql db.conn { */
	/* 	update GitRepo set repo */
	/* } */
}
