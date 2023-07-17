module models

pub struct BuildConfig {
pub:
	target_id  int
	kind       string
	url        string
	branch     string
	path       string
	repo       string
	base_image string
	force      bool
	timeout    int
}

// str return a single-line string representation of a build log
pub fn (c BuildConfig) str() string {
	return '{ target: ${c.target_id}, kind: ${c.kind}, url: ${c.url}, branch: ${c.branch}, path: ${c.path}, repo: ${c.repo}, base_image: ${c.base_image}, force: ${c.force}, timeout: ${c.timeout} }'
}
