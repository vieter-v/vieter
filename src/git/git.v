module git

import os
import json

pub struct GitRepo {
pub:
	url    string [required]
	branch string [required]
}

// read_repos reads the given JSON file & parses it as a list of Git repos
pub fn read_repos(path string) ?[]GitRepo {
	if !os.exists(path) {
		mut f := os.create(path) ?

		defer {
			f.close()
		}

		f.write_string('[]') ?

		return []
	}

	content := os.read_file(path) ?
	res := json.decode([]GitRepo, content) ?
	return res
}

// write_repos writes a list of repositories back to a given file
pub fn write_repos(path string, repos []GitRepo) ? {
	mut f := os.create(path) ?

	defer {
		f.close()
	}

	value := json.encode(repos)
	f.write_string(value) ?
}
