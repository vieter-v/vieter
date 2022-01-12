module archive

#flag -larchive
#include "archive.h"
#include "archive_entry.h"

struct C.archive {}

struct C.archive_entry {}

// Create a new archive struct
fn C.archive_read_new() &C.archive
fn C.archive_read_support_filter_all(&C.archive)
fn C.archive_read_support_format_all(&C.archive)
fn C.archive_read_open_filename(&C.archive, &char, int) int
fn C.archive_read_next_header(&C.archive, &&C.archive_entry) int
fn C.archive_entry_pathname(&C.archive_entry) &char
fn C.archive_read_data_skip(&C.archive)
fn C.archive_read_free(&C.archive) int
fn C.archive_read_data(&C.archive, voidptr, int)
fn C.archive_entry_size(&C.archive_entry) int

pub fn list_filenames() {
	a := C.archive_read_new()
	entry := &C.archive_entry{}
	mut r := 0

	C.archive_read_support_filter_all(a)
	C.archive_read_support_format_all(a)

	r = C.archive_read_open_filename(a, c'test/homebank-5.5.1-1-x86_64.pkg.tar.zst', 10240)

	for (C.archive_read_next_header(a, &entry) == C.ARCHIVE_OK) {
		println(cstring_to_vstring(C.archive_entry_pathname(entry)))
		C.archive_read_data_skip(a)  // Note 2
	}

	r = C.archive_read_free(a)  // Note 3
}

pub fn get_pkg_info(pkg_path string) ?string {
	a := C.archive_read_new()
	entry := &C.archive_entry{}
	mut r := 0

	C.archive_read_support_filter_all(a)
	C.archive_read_support_format_all(a)

	// TODO find out where does this 10240 come from
	println('1')
	r = C.archive_read_open_filename(a, &char(pkg_path.str), 10240)

	if r != C.ARCHIVE_OK {
		return error('Failed to open package.')
	}

	println('2')
	// We iterate over every header in search of the .PKGINFO one
	mut buf := []byte{}
	for C.archive_read_next_header(a, &entry) == C.ARCHIVE_OK {
		// TODO possibly avoid this cstring_to_vstring
		if cstring_to_vstring(C.archive_entry_pathname(entry)) == '.PKGINFO' {
			size := C.archive_entry_size(entry)

			buf = []byte{len: size}
			C.archive_read_data(a, voidptr(&buf), size)
			break
		}else{
			C.archive_read_data_skip(a)
		}
	}

	r = C.archive_read_free(a)  // Note 3
	return buf.bytestr()
}
