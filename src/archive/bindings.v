module archive

#flag -larchive

#include "archive.h"

struct C.archive {}

// Create a new archive struct
fn C.archive_read_new() &C.archive

// Configure the archive to work with zstd compression
fn C.archive_read_support_filter_zstd(&C.archive)

// Configure the archive to work with a tarball content
fn C.archive_read_support_format_tar(&C.archive)

// Open an archive for reading
fn C.archive_read_open_filename(&C.archive, &char, int) int

// Go to next entry header in archive
fn C.archive_read_next_header(&C.archive, &&C.archive_entry) int

// Skip reading the current entry
fn C.archive_read_data_skip(&C.archive)

// Free an archive
fn C.archive_read_free(&C.archive) int

// Read an archive entry's contents into a pointer
fn C.archive_read_data(&C.archive, voidptr, int)

#include "archive_entry.h"

struct C.archive_entry {}

// Create a new archive_entry struct
fn C.archive_entry_new() &C.archive_entry

// Get the filename of the given entry
fn C.archive_entry_pathname(&C.archive_entry) &char

// Get an entry's file size
// Note: this function actually returns an i64, but as this can't be used as an arugment to malloc, we'll just roll with it & assume an entry is never bigger than 4 gigs
fn C.archive_entry_size(&C.archive_entry) int

#include <string.h>

// Compare two C strings; 0 means they're equal
fn C.strcmp(&char, &char) int
