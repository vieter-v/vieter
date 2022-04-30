module package

import os
import util

// Represents a read archive
struct Pkg {
pub:
	path        string   [required]
	info        PkgInfo  [required]
	files       []string [required]
	compression int      [required]
}

// Represents the contents of a .PKGINFO file
struct PkgInfo {
pub mut:
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
	// md5sum      string
	// sha256sum   string
	pgpsig     string
	pgpsigsize i64
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

// checksum calculates the md5 & sha256 hash of the package
pub fn (p &Pkg) checksum() ?(string, string) {
	return util.hash_file(p.path)
}

// parse_pkg_info_string parses a PkgInfo object from a string
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
			'size' { pkg_info.size = value.int() }
			'url' { pkg_info.url = value }
			'arch' { pkg_info.arch = value }
			'builddate' { pkg_info.build_date = value.int() }
			'packager' { pkg_info.packager = value }
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
			// There's no real point in trying to exactly manage which fields
			// are allowed, so we just ignore any we don't explicitely need for
			// in the db file
			else { continue }
		}
	}

	return pkg_info
}

// read_pkg_archive extracts the file list & .PKGINFO contents from an archive
// NOTE: this command only supports zstd-, xz- & gzip-compressed tarballs.
pub fn read_pkg_archive(pkg_path string) ?Pkg {
	if !os.is_file(pkg_path) {
		return error("'$pkg_path' doesn't exist or isn't a file.")
	}

	a := C.archive_read_new()
	entry := C.archive_entry_new()

	// Sinds 2020, all newly built Arch packages use zstd
	C.archive_read_support_filter_zstd(a)
	C.archive_read_support_filter_gzip(a)
	C.archive_read_support_filter_xz(a)
	// The content should always be a tarball
	C.archive_read_support_format_tar(a)

	// TODO find out where does this 10240 come from
	r := C.archive_read_open_filename(a, &char(pkg_path.str), 10240)

	if r != C.ARCHIVE_OK {
		return error('Failed to open package.')
	}

	defer {
		C.archive_read_free(a)
	}

	// 0: no compression (just a tarball)
	// 1: gzip
	// 14: zstd
	compression_code := C.archive_filter_code(a, 0)

	mut files := []string{}
	mut pkg_info := PkgInfo{}

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
			buf := unsafe { malloc(size) }
			defer {
				unsafe {
					free(buf)
				}
			}
			C.archive_read_data(a, buf, size)

			pkg_text := unsafe { buf.vstring_with_len(size).clone() }

			pkg_info = parse_pkg_info_string(pkg_text) ?
		} else {
			C.archive_read_data_skip(a)
		}
	}

	pkg_info.csize = i64(os.file_size(pkg_path))

	return Pkg{
		path: pkg_path
		info: pkg_info
		files: files
		compression: compression_code
	}
}

// format_entry returns a string properly formatted to be added to a desc file.
fn format_entry(key string, value string) string {
	return '\n%$key%\n$value\n'
}

// full_name returns the properly formatted name for the package, including
// version & architecture
pub fn (pkg &Pkg) full_name() string {
	p := pkg.info
	return '$p.name-$p.version-$p.arch'
}

// filename returns the correct filename of the package file
pub fn (pkg &Pkg) filename() string {
	ext := match pkg.compression {
		0 { '.tar' }
		1 { '.tar.gz' }
		6 { '.tar.xz' }
		14 { '.tar.zst' }
		else { panic("Another compression code shouldn't be possible. Faulty code: $pkg.compression") }
	}

	return '${pkg.full_name()}.pkg$ext'
}

// to_desc returns a desc file valid string representation
// TODO calculate md5 & sha256 instead of believing the file
pub fn (pkg &Pkg) to_desc() string {
	p := pkg.info

	// filename
	mut desc := '%FILENAME%\n$pkg.filename()\n'

	desc += format_entry('NAME', p.name)
	desc += format_entry('BASE', p.base)
	desc += format_entry('VERSION', p.version)

	if p.description.len > 0 {
		desc += format_entry('DESC', p.description)
	}

	if p.groups.len > 0 {
		desc += format_entry('GROUPS', p.groups.join_lines())
	}

	desc += format_entry('CSIZE', p.csize.str())
	desc += format_entry('ISIZE', p.size.str())

	md5sum, sha256sum := pkg.checksum() or { '', '' }

	desc += format_entry('MD5SUM', md5sum)
	desc += format_entry('SHA256SUM', sha256sum)

	// TODO add pgpsig stuff

	if p.url.len > 0 {
		desc += format_entry('URL', p.url)
	}

	if p.licenses.len > 0 {
		desc += format_entry('LICENSE', p.licenses.join_lines())
	}

	desc += format_entry('ARCH', p.arch)
	desc += format_entry('BUILDDATE', p.build_date.str())
	desc += format_entry('PACKAGER', p.packager)

	if p.replaces.len > 0 {
		desc += format_entry('REPLACES', p.replaces.join_lines())
	}

	if p.conflicts.len > 0 {
		desc += format_entry('CONFLICTS', p.conflicts.join_lines())
	}

	if p.provides.len > 0 {
		desc += format_entry('PROVIDES', p.provides.join_lines())
	}

	if p.depends.len > 0 {
		desc += format_entry('DEPENDS', p.depends.join_lines())
	}

	if p.optdepends.len > 0 {
		desc += format_entry('OPTDEPENDS', p.optdepends.join_lines())
	}

	if p.makedepends.len > 0 {
		desc += format_entry('MAKEDEPENDS', p.makedepends.join_lines())
	}

	if p.checkdepends.len > 0 {
		desc += format_entry('CHECKDEPENDS', p.checkdepends.join_lines())
	}

	return '$desc\n'
}

// to_files returns a files file valid string representation
pub fn (pkg &Pkg) to_files() string {
	return '%FILES%\n$pkg.files.join_lines()\n'
}
