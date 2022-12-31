module models

pub const valid_kinds = ['git', 'url']

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
	id   int    [primary; sql: serial]
	kind string [nonull]
	// If kind is git: URL of the Git repository
	// If kind is url: URL to PKGBUILD file
	url string [nonull]
	// Branch of the Git repository to use; only applicable when kind is git.
	// If not provided, the repository is cloned with the default branch.
	branch string
	// Which repo the builder should publish packages to
	repo string [nonull]
	// Cron schedule describing how frequently to build the repo.
	schedule string
	// Subdirectory in the Git repository to cd into
	path string
	// On which architectures the package is allowed to be built. In reality,
	// this controls which agents will build this package when scheduled.
	arch []TargetArch [fkey: 'target_id']
}

// str returns a string representation.
pub fn (t &Target) str() string {
	mut parts := [
		'id: $t.id',
		'kind: $t.kind',
		'url: $t.url',
		'branch: $t.branch',
		'path: $t.path',
		'repo: $t.repo',
		'schedule: $t.schedule',
		'arch: ${t.arch.map(it.value).join(', ')}',
	]
	str := parts.join('\n')

	return str
}

// as_build_config converts a Target into a BuildConfig, given some extra
// needed information.
pub fn (t &Target) as_build_config(base_image string, force bool) BuildConfig {
	return BuildConfig{
		target_id: t.id
		kind: t.kind
		url: t.url
		branch: t.branch
		path: t.path
		repo: t.repo
		base_image: base_image
		force: force
	}
}

[params]
pub struct TargetFilter {
pub mut:
	limit  u64 = 25
	offset u64
	repo   string
	query  string
}
