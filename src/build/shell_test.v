module build

import models { Target }

fn test_create_build_script_git_branch() {
	target := Target{
		id: 1
		kind: 'git'
		url: 'https://examplerepo.com'
		branch: 'main'
		repo: 'vieter'
	}
	build_script := create_build_script('https://example.com', target, 'x86_64')
	expected := $embed_file('build_script_git_branch.sh')

	assert build_script == expected.to_string().trim_space()
}

fn test_create_build_script_git() {
	target := Target{
		id: 1
		kind: 'git'
		url: 'https://examplerepo.com'
		repo: 'vieter'
	}
	build_script := create_build_script('https://example.com', target, 'x86_64')
	expected := $embed_file('build_script_git.sh')

	assert build_script == expected.to_string().trim_space()
}

fn test_create_build_script_url() {
	target := Target{
		id: 1
		kind: 'url'
		url: 'https://examplerepo.com'
		repo: 'vieter'
	}
	build_script := create_build_script('https://example.com', target, 'x86_64')
	expected := $embed_file('build_script_url.sh')

	assert build_script == expected.to_string().trim_space()
}
