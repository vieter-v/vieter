module main

import vweb
import os

const port = 8000

struct App {
	vweb.Context
	api_key  string [required]
	repo_dir string [required]
}

[noreturn]
fn exit_with_message(code int, msg string) {
	eprintln(msg)
	exit(code)
}

[put; '/pkgs/:filename']
fn (mut app App) put_package(filename string) vweb.Result {
	os.write_file('$app.repo_dir/$filename', app.req.data) or {
		return app.text(err.msg)
	}

	return app.text('yeet')
}

fn main() {
	key := os.getenv_opt('API_KEY') or { exit_with_message(1, 'No API key was provided.') }
	repo_dir := os.getenv_opt('REPO_DIR') or {
		exit_with_message(1, 'No repo directory was configured.')
	}
	println(repo_dir)

	// We create the upload directory during startup
	if !os.is_dir(repo_dir) {
		os.mkdir_all(repo_dir) or { exit_with_message(2, "Failed to create repo directory '$repo_dir'.") }

		println("Repo directory '$repo_dir' created.")
	}

	vweb.run(&App{
		api_key: key
		repo_dir: repo_dir
	}, port)
}
