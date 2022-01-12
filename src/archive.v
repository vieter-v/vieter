module archive

#flag -larchive
#include "archive.h"
#include "archive_entry.h"

struct C.archive {}

struct C.archive_entry {}

fn C.archive_read_new() &C.archive
fn C.archive_read_support_filter_all(&C.archive)
fn C.archive_read_support_format_all(&C.archive)

pub fn list_filenames() {
	a := C.archive_read_new()
	C.archive_read_support_filter_all(a)
	C.archive_read_support_format_all(a)
	println(a)
}
