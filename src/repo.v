module repo

import os

const pkgs_subpath = 'pkgs'

// Dummy struct to work around the fact that you can only share structs, maps &
// arrays
pub struct Dummy {
	x int
}

// This struct manages a single repository.
pub struct Repo {
mut:
	mutex shared Dummy
pub:
	// Where to store repository files; should exist
	repo_dir string [required]
	// Where to find packages; packages are expected to all be in the same directory
	pkg_dir string [required]
}

// contains returns whether the repository contains the given package.
pub fn (r &Repo) contains(pkg string) bool {
	return os.exists(os.join_path(r.repo_dir, 'files', pkg))
}

// add adds the given package to the repo. If false, the package was already
// present in the repository.
pub fn (r &Repo) add(pkg string) ?bool {
	return false
}

// generate re-generates the db & files archives.
fn (r &Repo) genenerate() ? {
}

// pkg_path returns path to the given package, prepended with the repo's path.
pub fn (r &Repo) pkg_path(pkg string) string {
	return os.join_path_single(r.pkg_dir, pkg)
}

// exists checks whether a package file exists
pub fn (r &Repo) exists(pkg string) bool {
	return os.exists(r.pkg_path(pkg))
}

// db_path returns the full path to the database file
pub fn (r &Repo) db_path() string {
	return os.join_path_single(r.repo_dir, 'repo.tar.gz')
}

// add_package adds a package to the repository
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
