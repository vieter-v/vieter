module archive

import os

#flag -larchive
#include "archive.h"
#include "archive_entry.h"
#include <string.h>

struct C.archive {}

struct C.archive_entry {}

// Create a new archive struct
fn C.archive_read_new() &C.archive
fn C.archive_entry_new() &C.archive_entry
fn C.archive_read_support_filter_all(&C.archive)
fn C.archive_read_support_format_all(&C.archive)
// Open an archive for reading
fn C.archive_read_open_filename(&C.archive, &char, int) int
fn C.archive_read_next_header(&C.archive, &&C.archive_entry) int
fn C.archive_read_next_header2(&C.archive, &C.archive_entry) int
fn C.archive_entry_pathname(&C.archive_entry) &char
fn C.archive_read_data_skip(&C.archive)
fn C.archive_read_free(&C.archive) int
fn C.archive_read_data(&C.archive, voidptr, int)
fn C.archive_entry_size(&C.archive_entry) int

fn C.strcmp(&char, &char) int

// pub fn list_filenames() {
// 	a := C.archive_read_new()
// 	entry := &C.archive_entry{}
// 	mut r := 0

// 	C.archive_read_support_filter_all(a)
// 	C.archive_read_support_format_all(a)

// 	r = C.archive_read_open_filename(a, c'test/homebank-5.5.1-1-x86_64.pkg.tar.zst', 10240)

// 	for (C.archive_read_next_header(a, &entry) == C.ARCHIVE_OK) {
// 		println(cstring_to_vstring(C.archive_entry_pathname(entry)))
// 		C.archive_read_data_skip(a)  // Note 2
// 	}

// 	r = C.archive_read_free(a)  // Note 3
// }

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
		}else{
			C.archive_read_data_skip(a)
		}
	}

	return unsafe { cstring_to_vstring(&char(buf)) }
}
