module git

import os
import json

pub struct GitRepo {
pub mut:
	// URL of the Git repository
	url string
	// Branch of the Git repository to use
	branch string
	// On which architectures the package is allowed to be built. In reality,
	// this controls which builders will periodically build the image.
	arch []string
}

pub fn (mut r GitRepo) patch_from_params(params map[string]string) {
	$for field in GitRepo.fields {
		if field.name in params {
			$if field.typ is string {
				r.$(field.name) = params[field.name]
				// This specific type check is needed for the compiler to ensure
				// our types are correct
			} $else $if field.typ is []string {
				r.$(field.name) = params[field.name].split(',')
			}
		}
	}
}

pub fn read_repos(path string) ?map[string]GitRepo {
	if !os.exists(path) {
		mut f := os.create(path) ?

		defer {
			f.close()
		}

		f.write_string('{}') ?

		return {}
	}

	content := os.read_file(path) ?
	res := json.decode(map[string]GitRepo, content) ?

	return res
}

pub fn write_repos(path string, repos &map[string]GitRepo) ? {
	mut f := os.create(path) ?

	defer {
		f.close()
	}

	value := json.encode(repos)
	f.write_string(value) ?
}

pub fn repo_from_params(params map[string]string) ?GitRepo {
	mut repo := GitRepo{}

	// If we're creating a new GitRepo, we want all fields to be present before
	// "patching".
	$for field in GitRepo.fields {
		if field.name !in params {
			return error('Missing parameter: ${field.name}.')
		}
	}
	repo.patch_from_params(params)

	return repo
}
