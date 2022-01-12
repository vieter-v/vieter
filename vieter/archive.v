module archive

#include "libarchive/archive.h"
#include "libarchive/archive_entry.h"

struct C.archive {}
struct C.archive_entry {}

fn C.archive_read_new() &C.archive

pub fn list_filenames() {
	a := C.archive_read_new()
}
