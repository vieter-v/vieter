module models

pub struct TargetArch {
pub:
	id        int    [primary; sql: serial]
	target_id int    [nonull]
	value     string [nonull]
}

// str returns a string representation.
pub fn (gra &TargetArch) str() string {
	return gra.value
}

pub struct Target {
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
	arch []TargetArch [fkey: 'target_id']
}

// str returns a string representation.
pub fn (gr &Target) str() string {
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
pub struct TargetFilter {
pub mut:
	limit  u64 = 25
	offset u64
	repo   string
}
