module build

import models { Target }

fn test_create_build_script() {
	target := Target{
		id: 1
		url: 'https://examplerepo.com'
		branch: 'main'
		repo: 'vieter'
	}
	build_script := create_build_script('https://example.com', target, 'x86_64')
	expected := $embed_file('build_script.sh')

	assert build_script == expected.to_string().trim_space()
}
