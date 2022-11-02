module repo

import os

// remove_pkg_from_arch_repo removes a package from an arch-repo's database. It
// returns false if the package wasn't present in the database. It also
// optionally re-syncs the repo archives.
pub fn (r &RepoGroupManager) remove_pkg_from_arch_repo(repo string, arch string, pkg_name string, sync bool) !bool {
	repo_dir := os.join_path(r.repos_dir, repo, arch)

	// If the repository doesn't exist yet, the result is automatically false
	if !os.exists(repo_dir) {
		return false
	}

	// We iterate over every directory in the repo dir
	// TODO filter so we only check directories
	for d in os.ls(repo_dir)! {
		// Because a repository only allows a single version of each package,
		// we need only compare whether the name of the package is the same,
		// not the version.
		name := d.split('-')#[..-2].join('-')

		if name == pkg_name {
			// We lock the mutex here to prevent other routines from creating a
			// new archive while we remove an entry
			lock r.mutex {
				os.rmdir_all(os.join_path_single(repo_dir, d))!
			}

			// Also remove the package archive
			repo_pkg_dir := os.join_path(r.pkg_dir, repo, arch)

			archives := os.ls(repo_pkg_dir)!.filter(it.split('-')#[..-3].join('-') == name)

			for archive_name in archives {
				full_path := os.join_path_single(repo_pkg_dir, archive_name)
				os.rm(full_path)!
			}

			// Sync the db archives if requested
			if sync {
				r.sync(repo, arch)!
			}

			return true
		}
	}

	return false
}

// remove_arch_repo removes an arch-repo & its packages.
pub fn (r &RepoGroupManager) remove_arch_repo(repo string, arch string) !bool {
	repo_dir := os.join_path(r.repos_dir, repo, arch)

	// If the repository doesn't exist yet, the result is automatically false
	if !os.exists(repo_dir) {
		return false
	}

	os.rmdir_all(repo_dir)!

	pkg_dir := os.join_path(r.pkg_dir, repo, arch)
	os.rmdir_all(pkg_dir)!

	return true
}

// remove_repo removes a repo & its packages.
pub fn (r &RepoGroupManager) remove_repo(repo string) !bool {
	repo_dir := os.join_path_single(r.repos_dir, repo)

	// If the repository doesn't exist yet, the result is automatically false
	if !os.exists(repo_dir) {
		return false
	}

	os.rmdir_all(repo_dir)!

	pkg_dir := os.join_path_single(r.pkg_dir, repo)
	os.rmdir_all(pkg_dir)!

	return true
}
