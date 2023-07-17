module package

// format_entry returns a string properly formatted to be added to a desc file.
[inline]
fn format_entry(key string, value string) string {
	return '\n%${key}%\n${value}\n'
}

// full_name returns the properly formatted name for the package, including
// version & architecture
pub fn (pkg &Pkg) full_name() string {
	p := pkg.info
	return '${p.name}-${p.version}-${p.arch}'
}

// filename returns the correct filename of the package file
pub fn (pkg &Pkg) filename() string {
	ext := match pkg.compression {
		0 { '.tar' }
		1 { '.tar.gz' }
		6 { '.tar.xz' }
		14 { '.tar.zst' }
		else { panic("Another compression code shouldn't be possible. Faulty code: ${pkg.compression}") }
	}

	return '${pkg.full_name()}.pkg${ext}'
}

// to_desc returns a desc file valid string representation
pub fn (pkg &Pkg) to_desc() !string {
	p := pkg.info

	// filename
	mut desc := '%FILENAME%\n${pkg.filename()}\n'

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

	sha256sum := pkg.checksum()!

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

	return '${desc}\n'
}

// to_files returns a files file valid string representation
pub fn (pkg &Pkg) to_files() string {
	return '%FILES%\n${pkg.files.join_lines()}\n'
}
