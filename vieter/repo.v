module repo

import os

pub fn add_package(db_path string, pkg_path string) ? {
	res := os.execute("repo-add '$db_path' '$pkg_path'")

	if res.exit_code != 0 {
		println(res.output)
		return error('repo-add failed.')
	}
}
