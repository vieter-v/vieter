module archive

#flag -larchive
#include "archive.h"
#include "archive_entry.h"

struct C.archive {}

struct C.archive_entry {}

fn C.archive_read_new() &C.archive
fn C.archive_read_support_filter_all(&C.archive)
fn C.archive_read_support_format_all(&C.archive)
fn C.archive_read_open_filename(&C.archive, &char, int) int
fn C.archive_read_next_header(&C.archive, &&C.archive_entry) int
fn C.archive_entry_pathname(&C.archive_entry) &char
fn C.archive_read_data_skip(&C.archive)
fn C.archive_read_free(&C.archive) int

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
