module models

pub struct GitRepoArch {
pub:
	id      int    [primary; sql: serial]
	repo_id int    [nonull]
	value   string [nonull]
}

// str returns a string representation.
pub fn (gra &GitRepoArch) str() string {
	return gra.value
}

pub struct GitRepo {
pub mut:
	id int [primary; sql: serial]
	// URL of the Git repository
	url string [nonull]
	// Branch of the Git repository to use
	branch string [nonull]
	// Which repo the builder should publish packages to
	repo string [nonull]
	// Cron schedule describing how frequently to build the repo.
	schedule string
	// On which architectures the package is allowed to be built. In reality,
	// this controls which builders will periodically build the image.
	arch []GitRepoArch [fkey: 'repo_id']
}

// str returns a string representation.
pub fn (gr &GitRepo) str() string {
	mut parts := [
		'id: $gr.id',
		'url: $gr.url',
		'branch: $gr.branch',
		'repo: $gr.repo',
		'schedule: $gr.schedule',
		'arch: ${gr.arch.map(it.value).join(', ')}',
	]
	str := parts.join('\n')

	return str
}

[params]
pub struct GitRepoFilter {
pub mut:
	limit  u64 = 25
	offset u64
	repo   string
}
