module repo

import os

const pkgs_subpath = 'pkgs'

// Handles management of a repository. Package files are stored in '$dir/pkgs'
// & moved there if necessary.
pub struct Repo {
mut:
	mutex shared int = 0
pub:
	dir string [required]
	name string [required]
}

// Returns path to the given package, prepended with the repo's path.
pub fn (r &Repo) pkg_path(pkg string) string {
	return os.join_path(r.dir, pkgs_subpath, pkg)
}

pub fn (r &Repo) exists(pkg string) bool {
	return os.exists(r.pkg_path(pkg))
}

// Returns the full path to the database file
pub fn (r &Repo) db_path() string {
	return os.join_path_single(r.dir, '${r.name}.tar.gz')
}

pub fn (r &Repo) add_package(pkg_path string) ? {
	mut res := os.Result{}

	lock r.mutex {
		res = os.execute("repo-add '$r.db_path()' '$pkg_path'")
	}

	if res.exit_code != 0 {
		println(res.output)
		return error('repo-add failed.')
	}
}
