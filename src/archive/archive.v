module archive

import os

pub fn get_pkg_info(pkg_path string) ?string {
	if !os.is_file(pkg_path) {
		return error("'$pkg_path' doesn't exist or isn't a file.")
	}

	a := C.archive_read_new()
	entry := C.archive_entry_new()
	mut r := 0

	C.archive_read_support_filter_all(a)
	C.archive_read_support_format_all(a)

	// TODO find out where does this 10240 come from
	r = C.archive_read_open_filename(a, &char(pkg_path.str), 10240)
	defer {
		C.archive_read_free(a)
	}

	if r != C.ARCHIVE_OK {
		return error('Failed to open package.')
	}

	// We iterate over every header in search of the .PKGINFO one
	mut buf := voidptr(0)
	for C.archive_read_next_header(a, &entry) == C.ARCHIVE_OK {
		if C.strcmp(C.archive_entry_pathname(entry), c'.PKGINFO') == 0 {
			size := C.archive_entry_size(entry)

			// TODO can this unsafe block be avoided?
			buf = unsafe { malloc(size) }
			C.archive_read_data(a, voidptr(buf), size)
			break
		} else {
			C.archive_read_data_skip(a)
		}
	}

	return unsafe { cstring_to_vstring(&char(buf)) }
}
