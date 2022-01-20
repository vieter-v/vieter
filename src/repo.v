module repo

import os
import package

// subpath where the uncompressed version of the files archive is stored
const files_subpath = 'files'

// subpath where the uncompressed version of the repo archive is stored
const repo_subpath = 'repo'

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

// new creates a new Repo & creates the directories as needed
pub fn new(repo_dir string, pkg_dir string) ?Repo {
	if !os.is_dir(repo_dir) {
		os.mkdir_all(repo_dir) or { return error('Failed to create repo directory.') }
	}

	if !os.is_dir(pkg_dir) {
		os.mkdir_all(pkg_dir) or { return error('Failed to create package directory.') }
	}

	return Repo{
		repo_dir: repo_dir
		pkg_dir: pkg_dir
	}
}

// add_from_path adds a package from an arbitrary path & moves it into the pkgs
// directory if necessary.
pub fn (r &Repo) add_from_path(pkg_path string) ?bool {
	pkg := package.read_pkg(pkg_path) or { return error('Failed to read package file.') }

	added := r.add(pkg) ?

	// If the add was successful, we move the file to the packages directory
	if added {
		dest_path := os.real_path(os.join_path_single(r.pkg_dir, pkg.filename()))

		// Only move the file if it's not already in the package directory
		if dest_path != os.real_path(pkg_path) {
			os.mv(pkg_path, dest_path) ?
		}
	}

	return added
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

// Re-generate the repo archive files
fn (r &Repo) sync() ? {
	a := C.archive_write_new()
	entry := C.archive_entry_new()
	st := C.stat{}
	buf := [8192]byte{}

	// This makes the archive a gzip-compressed tarball
	C.archive_write_add_filter_gzip(a)
	C.archive_write_set_format_pax_restricted(a)

	repo_path := os.join_path_single(r.repo_dir, 'repo.db')

	C.archive_write_open_filename(a, &char(repo_path.str))

	// Iterate over each directory
	for d in os.ls(r.repo_dir) ?.filter(os.is_dir(os.join_path_single(r.repo_dir, it))) {
		inner_path := os.join_path_single(d, 'desc')
		actual_path := os.join_path_single(r.repo_dir, inner_path)

		unsafe {
			C.stat(&char(actual_path.str), &st)
		}

		C.archive_entry_set_pathname(entry, &char(inner_path.str))
		C.archive_entry_copy_stat(entry, &st)
		// C.archive_entry_set_size(entry, st.st_size)
		// C.archive_entry_set_filetype(entry, C.AE_IFREG)
		// C.archive_entry_set_perm(entry, 0o644)
		C.archive_write_header(a, entry)

		fd := C.open(&char(actual_path.str), C.O_RDONLY)
		mut len := C.read(fd, &buf, sizeof(buf))

		for len > 0 {
			C.archive_write_data(a, &buf, len)
			len = C.read(fd, &buf, sizeof(buf))
		}
		C.close(fd)

		C.archive_entry_clear(entry)
	}

	C.archive_write_close(a)
	C.archive_write_free(a)
}
