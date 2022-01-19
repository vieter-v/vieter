// Bindings for the libarchive library

#flag -larchive

#include "archive.h"

struct C.archive {}

// Create a new archive struct for reading
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

// Create a new archive struct for writing
fn C.archive_write_new() &C.archive

// Sets the filter for the archive to gzip
fn C.archive_write_add_filter_gzip(&C.archive)

// Sets to archive to "pax restricted" mode. Libarchive's "pax restricted"
// format is a tar format that uses pax extensions only when absolutely
// necessary. Most of the time, it will write plain ustar entries. This is the
// recommended tar format for most uses. You should explicitly use ustar format
// only when you have to create archives that will be readable on older
// systems; you should explicitly request pax format only when you need to
// preserve as many attributes as possible.
fn C.archive_write_set_format_pax_restricted(&C.archive)

// Opens up the filename for writing
fn C.archive_write_open_filename(&C.archive, &char)

// Write an entry to the archive file
fn C.archive_write_header(&C.archive, &C.archive_entry)

#include "archive_entry.h"

struct C.archive_entry {}

// Create a new archive_entry struct
fn C.archive_entry_new() &C.archive_entry

// Get the filename of the given entry
fn C.archive_entry_pathname(&C.archive_entry) &char

// Get an entry's file size
// Note: this function actually returns an i64, but as this can't be used as an
// arugment to malloc, we'll just roll with it & assume an entry is never
// bigger than 4 gigs
fn C.archive_entry_size(&C.archive_entry) int

// Set the pathname for the entry
fn C.archive_entry_set_pathname(&C.archive_entry, &char)

// Sets the file size of the entry
fn C.archive_entry_set_size(&C.archive_entry, i64)

// Sets the file type for an entry
fn C.archive_entry_set_filetype(&C.archive_entry, u32)

// Sets the file permissions for an entry
fn C.archive_entry_set_perm(&C.archive_entry, int)

#include <string.h>

// Compare two C strings; 0 means they're equal
fn C.strcmp(&char, &char) int
