module repo

import os
import package

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
	// Where to store repository files
	repo_dir string [required]
	// Where to find packages; packages are expected to all be in the same directory
	pkg_dir string [required]
}

pub struct RepoAddResult {
pub:
	added bool         [required]
	pkg   &package.Pkg [required]
}

// new creates a new Repo & creates the directories as needed
pub fn new(repo_dir string, pkg_dir string) ?Repo {
	if !os.is_dir(repo_dir) {
		os.mkdir_all(repo_dir) or { return error('Failed to create repo directory: $err.msg') }
	}

	if !os.is_dir(pkg_dir) {
		os.mkdir_all(pkg_dir) or { return error('Failed to create package directory: $err.msg') }
	}

	return Repo{
		repo_dir: repo_dir
		pkg_dir: pkg_dir
	}
}

// add_from_path adds a package from an arbitrary path & moves it into the pkgs
// directory if necessary.
pub fn (r &Repo) add_from_path(pkg_path string) ?RepoAddResult {
	pkg := package.read_pkg(pkg_path) or { return error('Failed to read package file: $err.msg') }

	added := r.add(pkg) ?

	// If the add was successful, we move the file to the packages directory
	if added {
		dest_path := os.real_path(os.join_path_single(r.pkg_dir, pkg.filename()))

		// Only move the file if it's not already in the package directory
		if dest_path != os.real_path(pkg_path) {
			os.mv(pkg_path, dest_path) ?
		}
	}

	return RepoAddResult{
		added: added
		pkg: &pkg
	}
}

// add adds a given Pkg to the repository
fn (r &Repo) add(pkg &package.Pkg) ?bool {
	pkg_dir := r.pkg_path(pkg)

	// We can't add the same package twice
	if os.exists(pkg_dir) {
		return false
	}

	os.mkdir(pkg_dir) or { return error('Failed to create package directory.') }

	os.write_file(os.join_path_single(pkg_dir, 'desc'), pkg.to_desc()) or {
		os.rmdir_all(pkg_dir) ?

		return error('Failed to write desc file.')
	}
	os.write_file(os.join_path_single(pkg_dir, 'files'), pkg.to_files()) or {
		os.rmdir_all(pkg_dir) ?

		return error('Failed to write files file.')
	}

	r.sync() ?

	return true
}

// Returns the path where the given package's desc & files files are stored
fn (r &Repo) pkg_path(pkg &package.Pkg) string {
	return os.join_path(r.repo_dir, '$pkg.info.name-$pkg.info.version')
}
