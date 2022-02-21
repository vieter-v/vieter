module server

import web
import os
import json

const repos_file = 'repos.json'

pub struct GitRepo {
pub:
	url    string [required]
	branch string [required]
}

fn read_repos(path string) ?[]GitRepo {
	if !os.exists(path) {
		mut f := os.create(path) ?

		defer {
			f.close()
		}

		f.write_string('[]') ?

		return []
	}

	content := os.read_file(path) ?
	res := json.decode([]GitRepo, content) ?
	return res
}

fn write_repos(path string, repos []GitRepo) ? {
	mut f := os.create(path) ?

	defer {
		f.close()
	}

	value := json.encode(repos)
	f.write_string(value) ?
}

['/api/repos'; get]
pub fn (mut app App) get_repos() web.Result {
	if !app.is_authorized() {
		return app.text('Unauthorized.')
	}

	repos := rlock app.git_mutex {
		read_repos(app.conf.repos_file) or {
			app.lerror('Failed to read repos file.')

			return app.server_error(500)
		}
	}

	return app.json(repos)
}

['/api/repos'; post]
pub fn (mut app App) post_repo() web.Result {
	if !app.is_authorized() {
		return app.text('Unauthorized.')
	}

	if !('url' in app.query && 'branch' in app.query) {
		return app.server_error(400)
	}

	new_repo := GitRepo{
		url: app.query['url']
		branch: app.query['branch']
	}

	mut repos := rlock app.git_mutex {
		read_repos(app.conf.repos_file) or {
			app.lerror('Failed to read repos file.')

			return app.server_error(500)
		}
	}

	// We need to check for duplicates
	for r in repos {
		if r == new_repo {
			return app.text('Duplicate repository.')
		}
	}

	repos << new_repo

	lock app.git_mutex {
		write_repos(app.conf.repos_file, repos) or { return app.server_error(500) }
	}

	return app.ok('Repo added successfully.')
}

['/api/repos'; delete]
pub fn (mut app App) delete_repo() web.Result {
	if !app.is_authorized() {
		return app.text('Unauthorized.')
	}

	if !('url' in app.query && 'branch' in app.query) {
		return app.server_error(400)
	}

	repo_to_remove := GitRepo{
		url: app.query['url']
		branch: app.query['branch']
	}

	mut repos := rlock app.git_mutex {
		read_repos(app.conf.repos_file) or {
			app.lerror('Failed to read repos file.')

			return app.server_error(500)
		}
	}
	filtered := repos.filter(it != repo_to_remove)

	lock app.git_mutex {
		write_repos(app.conf.repos_file, filtered) or { return app.server_error(500) }
	}

	return app.ok('Repo removed successfully.')
}
