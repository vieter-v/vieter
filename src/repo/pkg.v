module repo

import archive
import time

struct PkgInfo {
mut:
	// Single values
	name string
	base string
	version string
	description string
	size i64
	csize i64
	url string
	arch string
	build_date i64
	packager string
	md5sum string
	sha256sum string
	pgpsig string
	pgpsigsize i64

	// Array values
	groups []string
	licenses []string
	replaces []string
	depends []string
	conflicts []string
	provides []string
	optdepends []string
	makedepends []string
	checkdepends []string
}

pub fn get_pkg_info(pkg_path string) ?PkgInfo {
	pkg_info_str := archive.pkg_info_string(pkg_path) ?
	mut pkg_info := PkgInfo{}

	mut i := 0
	mut j := 0

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
