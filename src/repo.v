module repo

import os
import archive

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

// Returns whether the repository contains the given package.
pub fn (r &Repo) contains(pkg string) bool {
	return os.exists(os.join_path(r.repo_dir, 'files', pkg))
}

// Adds the given package to the repo. If false, the package was already
// present in the repository.
pub fn (r &Repo) add(pkg string) ?bool {
	return false
}

// Re-generate the db & files archives.
fn (r &Repo) genenerate() ? {
}

// Returns path to the given package, prepended with the repo's path.
pub fn (r &Repo) pkg_path(pkg string) string {
	return os.join_path_single(r.pkg_dir, pkg)
}

pub fn (r &Repo) exists(pkg string) bool {
	return os.exists(r.pkg_path(pkg))
}

// Returns the full path to the database file
pub fn (r &Repo) db_path() string {
	return os.join_path_single(r.repo_dir, 'repo.tar.gz')
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
