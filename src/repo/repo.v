module repo

import os
import package
import util

// Manages a group of repositories. Each repository contains one or more
// arch-repositories, each of which represent a specific architecture.
pub struct RepoGroupManager {
mut:
	mutex shared util.Dummy
pub:
	// Where to store repositories' files
	repos_dir string [required]
	// Where packages are stored; each repository gets its own subdirectory
	pkg_dir string [required]
	// The default architecture to use for a repository. In reality, this value
	// is only required when a package with architecture "any" is added as the
	// first package of a repository.
	default_arch string [required]
}

pub struct RepoAddResult {
pub:
	added bool         [required]
	pkg   &package.Pkg [required]
}

// new creates a new RepoGroupManager & creates the directories as needed
pub fn new(repos_dir string, pkg_dir string, default_arch string) ?RepoGroupManager {
	if !os.is_dir(repos_dir) {
		os.mkdir_all(repos_dir) or { return error('Failed to create repos directory: $err.msg') }
	}

	if !os.is_dir(pkg_dir) {
		os.mkdir_all(pkg_dir) or { return error('Failed to create package directory: $err.msg') }
	}

	return RepoGroupManager{
		repos_dir: repos_dir
		pkg_dir: pkg_dir
		default_arch: default_arch
	}
}

// add_pkg_from_path adds a package to a given repo, given the file path to the
// pkg archive. It's a wrapper around add_pkg_in_repo that parses the archive
// file, passes the result to add_pkg_in_repo, and moves the archive to
// r.pkg_dir if it was successfully added.
pub fn (r &RepoGroupManager) add_pkg_from_path(repo string, pkg_path string) ?RepoAddResult {
	pkg := package.read_pkg_archive(pkg_path) or {
		return error('Failed to read package file: $err.msg')
	}

	added := r.add_pkg_in_repo(repo, pkg) ?

	// If the add was successful, we move the file to the packages directory
	if added {
		repo_pkg_path := os.real_path(os.join_path_single(r.pkg_dir, repo))
		dest_path := os.join_path_single(repo_pkg_path, pkg.filename())

		// Only move the file if it's not already in the package directory
		if dest_path != os.real_path(pkg_path) {
			os.mkdir_all(repo_pkg_path) ?
			os.mv(pkg_path, dest_path) ?
		}
	}

	return RepoAddResult{
		added: added
		pkg: &pkg
	}
}

// add_pkg_in_repo adds a package to a given repo. This function is responsible
// for inspecting the package architecture. If said architecture is 'any', the
// package is added to each arch-repository within the given repo. A package of
// architecture 'any' will always be added to the arch-repo defined by
// r.default_arch. If this arch-repo doesn't exist yet, it will be created. If
// the architecture isn't 'any', the package is only added to the specific
// architecture.
fn (r &RepoGroupManager) add_pkg_in_repo(repo string, pkg &package.Pkg) ?bool {
	// A package without arch 'any' can be handled without any further checks
	if pkg.info.arch != 'any' {
		return r.add_pkg_in_arch_repo(repo, pkg.info.arch, pkg)
	}

	repo_dir := os.join_path_single(r.repos_dir, repo)

	mut arch_repos := []string{}

	// If this is the first package that's added to the repo, the directory
	// won't exist yet
	if os.exists(repo_dir) {
		// We get a listing of all currently present arch-repos in the given repo
		arch_repos = os.ls(repo_dir) ?.filter(os.is_dir(os.join_path_single(repo_dir,
			it)))
	}

	// The default_arch should always be updated when a package with arch 'any'
	// is added.
	if !arch_repos.contains(r.default_arch) {
		arch_repos << r.default_arch
	}

	mut added := false

	// We add the package to each repository. If any of the repositories
	// return true, the result of the function is also true.
	for arch in arch_repos {
		added = added || r.add_pkg_in_arch_repo(repo, arch, pkg) ?
	}

	return added
}

// add_pkg_in_arch_repo is the function that actually adds a package to a given
// arch-repo. It records the package's data in the arch-repo's desc & files
// files, and afterwards updates the db & files archives to reflect these
// changes. The function returns false if the package was already present in
// the repo, and true otherwise.
fn (r &RepoGroupManager) add_pkg_in_arch_repo(repo string, arch string, pkg &package.Pkg) ?bool {
	pkg_dir := os.join_path(r.repos_dir, repo, arch, '$pkg.info.name-$pkg.info.version')

	// We can't add the same package twice
	if os.exists(pkg_dir) {
		return false
	}

	// We remove the older package version first, if present
	r.remove_pkg_from_arch_repo(repo, arch, pkg, false) ?

	os.mkdir_all(pkg_dir) or { return error('Failed to create package directory.') }

	os.write_file(os.join_path_single(pkg_dir, 'desc'), pkg.to_desc()) or {
		os.rmdir_all(pkg_dir) ?

		return error('Failed to write desc file.')
	}
	os.write_file(os.join_path_single(pkg_dir, 'files'), pkg.to_files()) or {
		os.rmdir_all(pkg_dir) ?

		return error('Failed to write files file.')
	}

	r.sync(repo, arch) ?

	return true
}

// remove_pkg_from_arch_repo removes a package from an arch-repo's database. It
// returns false if the package wasn't present in the database. It also
// optionally re-syncs the repo archives.
fn (r &RepoGroupManager) remove_pkg_from_arch_repo(repo string, arch string, pkg &package.Pkg, sync bool) ?bool {
	repo_dir := os.join_path(r.repos_dir, repo, arch)

	// If the repository doesn't exist yet, the result is automatically false
	if !os.exists(repo_dir) {
		return false
	}

	// We iterate over every directory in the repo dir
	// TODO filter so we only check directories
	for d in os.ls(repo_dir) ? {
		// Because a repository only allows a single version of each package,
		// we need only compare whether the name of the package is the same,
		// not the version.
		name := d.split('-')#[..-2].join('-')

		if name == pkg.info.name {
			// We lock the mutex here to prevent other routines from creating a
			// new archive while we remove an entry
			lock r.mutex {
				os.rmdir_all(os.join_path_single(repo_dir, d)) ?
			}

			if sync {
				r.sync(repo, arch) ?
			}

			return true
		}
	}

	return false
}
