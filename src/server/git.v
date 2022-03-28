module server

import web
import os
import json
import rand

pub struct GitRepo {
pub mut:
	// URL of the Git repository
	url    string
	// Branch of the Git repository to use
	branch string
	// On which architectures the package is allowed to be built. In reality,
	// this controls which builders will periodically build the image.
	arch   []string
}

fn (mut r GitRepo) patch_from_params(params map[string]string) {
	$for field in GitRepo.fields {
		if field.name in params {
			$if field.typ is string {
				r.$(field.name) = params[field.name]
			// This specific type check is needed for the compiler to ensure
			// our types are correct
			} $else $if field.typ is []string {
				r.$(field.name) = params[field.name].split(',')
			}
		}
	}
}

fn repo_from_params(params map[string]string) ?GitRepo {
	mut repo := GitRepo{}

	// If we're creating a new GitRepo, we want all fields to be present before
	// "patching".
	$for field in GitRepo.fields {
		if field.name !in params {
			return error('Missing parameter: ${field.name}.')
		}
	}

	repo.patch_from_params(params)

	return repo
}

fn read_repos(path string) ?map[string]GitRepo {
	if !os.exists(path) {
		mut f := os.create(path) ?

		defer {
			f.close()
		}

		f.write_string('{}') ?

		return {}
	}

	content := os.read_file(path) ?
	res := json.decode(map[string]GitRepo, content) ?
	return res
}

fn write_repos(path string, repos &map[string]GitRepo) ? {
	mut f := os.create(path) ?

	defer {
		f.close()
	}

	value := json.encode(repos)
	f.write_string(value) ?
}

['/api/repos'; get]
fn (mut app App) get_repos() web.Result {
	if !app.is_authorized() {
		return app.json(401, new_response('Unauthorized.'))
	}

	repos := rlock app.git_mutex {
		read_repos(app.conf.repos_file) or {
			app.lerror('Failed to read repos file.')

			return app.status(500)
		}
	}

	return app.json(200, new_data_response(repos))
}

['/api/repos/:id'; get]
fn (mut app App) get_single_repo(id string) web.Result {
	if !app.is_authorized() {
		return app.json(401, new_response('Unauthorized.'))
	}

	repos := rlock app.git_mutex {
		read_repos(app.conf.repos_file) or {
			app.lerror('Failed to read repos file.')

			return app.status(500)
		}
	}

	if id !in repos {
		return app.not_found()
	}

	repo := repos[id]

	return app.json(200, new_data_response(repo))
}

['/api/repos'; post]
fn (mut app App) post_repo() web.Result {
	if !app.is_authorized() {
		return app.json(401, new_response('Unauthorized.'))
	}

	new_repo := repo_from_params(app.query) or {
		return app.json(400, new_response(err.msg))
	}

	id := rand.uuid_v4()

	mut repos := rlock app.git_mutex {
		read_repos(app.conf.repos_file) or {
			app.lerror('Failed to read repos file.')

			return app.status(500)
		}
	}

	// We need to check for duplicates
	for _, repo in repos {
		if repo == new_repo {
			return app.json(400, new_response('Duplicate repository.'))
		}
	}

	repos[id] = new_repo

	lock app.git_mutex {
		write_repos(app.conf.repos_file, &repos) or { return app.status(500) }
	}

	return app.json(200, new_response('Repo added successfully.'))
}

['/api/repos/:id'; delete]
fn (mut app App) delete_repo(id string) web.Result {
	if !app.is_authorized() {
		return app.json(401, new_response('Unauthorized.'))
	}

	mut repos := rlock app.git_mutex {
		read_repos(app.conf.repos_file) or {
			app.lerror('Failed to read repos file.')

			return app.status(500)
		}
	}

	if id !in repos {
		return app.not_found()
	}

	repos.delete(id)

	lock app.git_mutex {
		write_repos(app.conf.repos_file, &repos) or { return app.server_error(500) }
	}

	return app.json(200, new_response('Repo removed successfully.'))
}

['/api/repos/:id'; patch]
fn (mut app App) patch_repo(id string) web.Result {
	if !app.is_authorized() {
		return app.json(401, new_response('Unauthorized.'))
	}

	mut repos := rlock app.git_mutex {
		read_repos(app.conf.repos_file) or {
			app.lerror('Failed to read repos file.')

			return app.status(500)
		}
	}

	if id !in repos {
		return app.not_found()
	}

	repos[id].patch_from_params(app.query)

	lock app.git_mutex {
		write_repos(app.conf.repos_file, &repos) or { return app.server_error(500) }
	}

	return app.json(200, new_response('Repo updated successfully.'))
}
