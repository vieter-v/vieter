module git

import os
import json

pub struct GitRepo {
pub:
	url    string [required]
	branch string [required]
}

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

pub fn write_repos(path string, repos []GitRepo) ? {
	mut f := os.create(path) ?

	defer {
		f.close()
	}

	value := json.encode(repos)
	f.write_string(value) ?
}
