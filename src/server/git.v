module server

import web
import git

const repos_file = 'repos.json'

['/api/repos'; get]
fn (mut app App) get_repos() web.Result {
	if !app.is_authorized() {
		return app.text('Unauthorized.')
	}

	repos := rlock app.git_mutex {
		git.read_repos(app.conf.repos_file) or {
			app.lerror('Failed to read repos file.')

			return app.server_error(500)
		}
	}

	return app.json(repos)
}

['/api/repos'; post]
fn (mut app App) post_repo() web.Result {
	if !app.is_authorized() {
		return app.text('Unauthorized.')
	}

	if !('url' in app.query && 'branch' in app.query) {
		return app.server_error(400)
	}

	new_repo := git.GitRepo{
		url: app.query['url']
		branch: app.query['branch']
	}

	mut repos := rlock app.git_mutex {
		git.read_repos(app.conf.repos_file) or {
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
		git.write_repos(app.conf.repos_file, repos) or { return app.server_error(500) }
	}

	return app.ok('Repo added successfully.')
}

['/api/repos'; delete]
fn (mut app App) delete_repo() web.Result {
	if !app.is_authorized() {
		return app.text('Unauthorized.')
	}

	if !('url' in app.query && 'branch' in app.query) {
		return app.server_error(400)
	}

	repo_to_remove := git.GitRepo{
		url: app.query['url']
		branch: app.query['branch']
	}

	mut repos := rlock app.git_mutex {
		git.read_repos(app.conf.repos_file) or {
			app.lerror('Failed to read repos file.')

			return app.server_error(500)
		}
	}
	filtered := repos.filter(it != repo_to_remove)

	lock app.git_mutex {
		git.write_repos(app.conf.repos_file, filtered) or { return app.server_error(500) }
	}

	return app.ok('Repo removed successfully.')
}
