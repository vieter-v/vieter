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
	data_dir string [required]
	// Where packages are stored; each architecture gets its own subdirectory
	pkg_dir string [required]
	// The default architecture to use for a repository. In reality, this value
	// is only required when a package with architecture "any" is added as the
	// first package to a repository.
	default_arch string [required]
}

pub struct RepoAddResult {
pub:
	added bool         [required]
	pkg   &package.Pkg [required]
}

// new creates a new RepoGroupManager & creates the directories as needed
pub fn new(data_dir string, pkg_dir string, default_arch string) ?RepoGroupManager {
	if !os.is_dir(data_dir) {
		os.mkdir_all(data_dir) or { return error('Failed to create repo directory: $err.msg') }
	}

	if !os.is_dir(pkg_dir) {
		os.mkdir_all(pkg_dir) or { return error('Failed to create package directory: $err.msg') }
	}

	return RepoGroupManager{
		data_dir: data_dir
		pkg_dir: pkg_dir
		default_arch: default_arch
	}
}

// add_from_path adds a package from an arbitrary path & moves it into the pkgs
// directory if necessary.
pub fn (r &RepoGroupManager) add_pkg_from_path(repo string, pkg_path string) ?RepoAddResult {
	pkg := package.read_pkg_archive(pkg_path) or { return error('Failed to read package file: $err.msg') }

	added := r.add_pkg_in_repo(repo, pkg) ?

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

fn (r &RepoGroupManager) add_pkg_in_repo(repo string, pkg &package.Pkg) ?bool {
	if pkg.info.arch == "any" {
		repo_dir := os.join_path_single(r.data_dir, repo)

		mut arch_repos := []string{}

		if os.exists(repo_dir) {
			// We get a listing of all currently present arch-repos in the given repo
			arch_repos = os.ls(repo_dir) ?.filter(os.is_dir(os.join_path_single(repo_dir, it)))
		}

		if arch_repos.len == 0 {
			arch_repos << r.default_arch
		}

		mut added := false

		for arch in arch_repos {
			added = added || r.add_pkg_in_arch_repo(repo, arch, pkg) ?
		}

		return added
	}else{
		return r.add_pkg_in_arch_repo(repo, pkg.info.arch, pkg)
	}
}

// add_pkg_in_repo adds the given package to the specified repo. A repo is an
// arbitrary subdirectory of r.repo_dir, but in practice, it will always be an
// architecture-specific version of some sub-repository.
fn (r &RepoGroupManager) add_pkg_in_arch_repo(repo string, arch string, pkg &package.Pkg) ?bool {
	pkg_dir := os.join_path(r.data_dir, repo, arch, '$pkg.info.name-$pkg.info.version')

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

// remove removes a package from the database. It returns false if the package
// wasn't present in the database.
fn (r &RepoGroupManager) remove_pkg_from_arch_repo(repo string, arch string, pkg &package.Pkg, sync bool) ?bool {
	repo_dir := os.join_path(r.data_dir, repo, arch)

	// If the repository doesn't exist yet, the result is automatically false
	if !os.exists(repo_dir) {
		return false
	}

	// We iterate over every directory in the repo dir
	// TODO filter so we only check directories
	for d in os.ls(repo_dir) ? {
		name := d.split('-')#[..-2].join('-')

		if name == pkg.info.name {
			// We lock the mutex here to prevent other routines from creating a
			// new archive while we removed an entry
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
