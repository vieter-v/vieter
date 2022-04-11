module repo

import os

fn archive_add_entry(archive &C.archive, entry &C.archive_entry, file_path &string, inner_path &string) {
	st := C.stat{}

	unsafe {
		C.stat(&char(file_path.str), &st)
	}

	C.archive_entry_set_pathname(entry, &char(inner_path.str))
	C.archive_entry_copy_stat(entry, &st)
	C.archive_write_header(archive, entry)

	mut fd := C.open(&char(file_path.str), C.O_RDONLY)
	defer {
		C.close(fd)
	}

	// Write the file to the archive
	buf := [8192]byte{}
	mut len := C.read(fd, &buf, sizeof(buf))

	for len > 0 {
		C.archive_write_data(archive, &buf, len)

		len = C.read(fd, &buf, sizeof(buf))
	}
}

// Re-generate the repo archive files
fn (r &RepoGroupManager) sync(repo string, arch string) ? {
	subrepo_path := os.join_path(r.repos_dir, repo, arch)

	lock r.mutex {
		a_db := C.archive_write_new()
		a_files := C.archive_write_new()

		entry := C.archive_entry_new()

		// This makes the archive a gzip-compressed tarball
		C.archive_write_add_filter_gzip(a_db)
		C.archive_write_set_format_pax_restricted(a_db)
		C.archive_write_add_filter_gzip(a_files)
		C.archive_write_set_format_pax_restricted(a_files)

		db_path := os.join_path_single(subrepo_path, '${repo}.db.tar.gz')
		files_path := os.join_path_single(subrepo_path, '${repo}.files.tar.gz')

		C.archive_write_open_filename(a_db, &char(db_path.str))
		C.archive_write_open_filename(a_files, &char(files_path.str))

		// Iterate over each directory
		for d in os.ls(subrepo_path) ?.filter(os.is_dir(os.join_path_single(subrepo_path,
			it))) {
			// desc
			mut inner_path := os.join_path_single(d, 'desc')
			mut actual_path := os.join_path_single(subrepo_path, inner_path)

			archive_add_entry(a_db, entry, actual_path, inner_path)
			archive_add_entry(a_files, entry, actual_path, inner_path)

			C.archive_entry_clear(entry)

			// files
			inner_path = os.join_path_single(d, 'files')
			actual_path = os.join_path_single(subrepo_path, inner_path)

			archive_add_entry(a_files, entry, actual_path, inner_path)

			C.archive_entry_clear(entry)
		}

		C.archive_write_close(a_db)
		C.archive_write_free(a_db)
		C.archive_write_close(a_files)
		C.archive_write_free(a_files)
	}
}
