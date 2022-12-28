module client

// remove_repo removes an entire repository.
pub fn (c &Client) remove_repo(repo string) ! {
	c.send_request<string>(.delete, '/$repo', {})!
}

// remove_arch_repo removes an entire arch-repo.
pub fn (c &Client) remove_arch_repo(repo string, arch string) ! {
	c.send_request<string>(.delete, '/$repo/$arch', {})!
}

// remove_package removes a single package from the given arch-repo.
pub fn (c &Client) remove_package(repo string, arch string, pkgname string) ! {
	c.send_request<string>(.delete, '/$repo/$arch/$pkgname', {})!
}
