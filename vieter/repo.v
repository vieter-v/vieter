module repo

import os

pub struct Repo {
	path string
}

pub fn (r Repo) add_package(pkg_path string) ? {
	res := os.execute("repo-add '$r.path' '$pkg_path'")

	if res.exit_code != 0 {
		println(res.output)
		return error('repo-add failed.')
	}
}
