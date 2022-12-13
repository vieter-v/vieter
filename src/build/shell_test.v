module build

import models

fn test_create_build_script_git_branch() {
	config := BuildConfig{
		target_id: 1
		kind: 'git'
		url: 'https://examplerepo.com'
		branch: 'main'
		repo: 'vieter'
		base_image: 'not-used:latest'
	}

	build_script := create_build_script('https://example.com', config, 'x86_64')
	expected := $embed_file('build_script_git_branch.sh')

	assert build_script == expected.to_string().trim_space()
}

fn test_create_build_script_git() {
	config := BuildConfig{
		target_id: 1
		kind: 'git'
		url: 'https://examplerepo.com'
		repo: 'vieter'
		base_image: 'not-used:latest'
	}

	build_script := create_build_script('https://example.com', config, 'x86_64')
	expected := $embed_file('build_script_git.sh')

	assert build_script == expected.to_string().trim_space()
}

fn test_create_build_script_url() {
	config := BuildConfig{
		target_id: 1
		kind: 'url'
		url: 'https://examplerepo.com'
		repo: 'vieter'
		base_image: 'not-used:latest'
	}

	build_script := create_build_script('https://example.com', config, 'x86_64')
	expected := $embed_file('build_script_url.sh')

	assert build_script == expected.to_string().trim_space()
}
