module build

fn test_create_build_script_git() {
	config := BuildConfig{
		target_id: 1
		kind: 'git'
		url: 'https://examplerepo.com'
		repo: 'vieter'
		base_image: 'not-used:latest'
	}

	build_script := create_build_script('https://example.com', config, 'x86_64')
	expected := $embed_file('scripts/git.sh')

	assert build_script == expected.to_string().trim_space()
}

fn test_create_build_script_git_path() {
	mut config := BuildConfig{
		target_id: 1
		kind: 'git'
		url: 'https://examplerepo.com'
		repo: 'vieter'
		path: 'example/path'
		base_image: 'not-used:latest'
	}

	mut build_script := create_build_script('https://example.com', config, 'x86_64')
	mut expected := $embed_file('scripts/git_path.sh')

	assert build_script == expected.to_string().trim_space()

	config = BuildConfig{
		...config
		path: 'example/path with spaces'
	}

	build_script = create_build_script('https://example.com', config, 'x86_64')
	expected = $embed_file('scripts/git_path_spaces.sh')

	assert build_script == expected.to_string().trim_space()
}

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
	expected := $embed_file('scripts/git_branch.sh')

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
	expected := $embed_file('scripts/url.sh')

	assert build_script == expected.to_string().trim_space()
}
