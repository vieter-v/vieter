module pkg

import time
import os

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

// Represents a read archive
struct Pkg {
pub:
	info  PkgInfo  [required]
	files []string [required]
}

// Represents the contents of a .PKGINFO file
struct PkgInfo {
mut:
	// Single values
	name        string
	base        string
	version     string
	description string
	size        i64
	csize       i64
	url         string
	arch        string
	build_date  i64
	packager    string
	md5sum      string
	sha256sum   string
	pgpsig      string
	pgpsigsize  i64
	// Array values
	groups       []string
	licenses     []string
	replaces     []string
	depends      []string
	conflicts    []string
	provides     []string
	optdepends   []string
	makedepends  []string
	checkdepends []string
}

fn parse_pkg_info_string(pkg_info_str &string) ?PkgInfo {
	mut pkg_info := PkgInfo{}

	// Iterate over the entire string
	for line in pkg_info_str.split_into_lines() {
		// Skip any comment lines
		if line.starts_with('#') {
			continue
		}
		parts := line.split_nth('=', 2)

		if parts.len < 2 {
			return error('Invalid line detected.')
		}

		value := parts[1].trim_space()
		key := parts[0].trim_space()

		match key {
			// Single values
			'pkgname' { pkg_info.name = value }
			'pkgbase' { pkg_info.base = value }
			'pkgver' { pkg_info.version = value }
			'pkgdesc' { pkg_info.description = value }
			'csize' { pkg_info.csize = value.int() }
			'size' { pkg_info.size = value.int() }
			'url' { pkg_info.url = value }
			'arch' { pkg_info.arch = value }
			'builddate' { pkg_info.build_date = value.int() }
			'packager' { pkg_info.packager = value }
			'md5sum' { pkg_info.md5sum = value }
			'sha256sum' { pkg_info.sha256sum = value }
			'pgpsig' { pkg_info.pgpsig = value }
			'pgpsigsize' { pkg_info.pgpsigsize = value.int() }
			// Array values
			'group' { pkg_info.groups << value }
			'license' { pkg_info.licenses << value }
			'replaces' { pkg_info.replaces << value }
			'depend' { pkg_info.depends << value }
			'conflict' { pkg_info.conflicts << value }
			'provides' { pkg_info.provides << value }
			'optdepend' { pkg_info.optdepends << value }
			'makedepend' { pkg_info.makedepends << value }
			'checkdepend' { pkg_info.checkdepends << value }
			else { return error("Invalid key '$key'.") }
		}
	}

	return pkg_info
}

// Extracts the file list & .PKGINFO contents from an archive
// NOTE: this command currently only supports zstd-compressed tarballs
pub fn read_pkg(pkg_path string) ?Pkg {
	if !os.is_file(pkg_path) {
		return error("'$pkg_path' doesn't exist or isn't a file.")
	}

	a := C.archive_read_new()
	entry := C.archive_entry_new()
	mut r := 0

	// Sinds 2020, all newly built Arch packages use zstd
	C.archive_read_support_filter_zstd(a)
	// The content should always be a tarball
	C.archive_read_support_format_tar(a)

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
	mut files := []string{}
	for C.archive_read_next_header(a, &entry) == C.ARCHIVE_OK {
		pathname := C.archive_entry_pathname(entry)

		ignored_names := [c'.BUILDINFO', c'.INSTALL', c'.MTREE', c'.PKGINFO', c'.CHANGELOG']
		if ignored_names.all(C.strcmp(it, pathname) != 0) {
			unsafe {
				files << cstring_to_vstring(pathname)
			}
		}

		if C.strcmp(pathname, c'.PKGINFO') == 0 {
			size := C.archive_entry_size(entry)

			// TODO can this unsafe block be avoided?
			buf = unsafe { malloc(size) }
			C.archive_read_data(a, voidptr(buf), size)
		} else {
			C.archive_read_data_skip(a)
		}
	}

	pkg_info := parse_pkg_info_string(unsafe { cstring_to_vstring(&char(buf)) }) ?

	return Pkg{
		info: pkg_info
		files: files
	}
}

// Represent a PkgInfo struct as a desc file
pub fn (p &PkgInfo) to_desc() string {
	// TODO calculate md5 & sha256 instead of believing the file
	mut desc := ''

	return desc
}
