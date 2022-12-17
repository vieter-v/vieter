module build

import models { BuildConfig }

// escape_shell_string escapes any characters that could be interpreted
// incorrectly by a shell. The resulting value should be safe to use inside an
// echo statement.
fn escape_shell_string(s string) string {
	return s.replace(r'\', r'\\').replace("'", r"'\''")
}

// echo_commands takes a list of shell commands & prepends each one with
// an echo call displaying said command.
pub fn echo_commands(cmds []string) []string {
	mut out := []string{cap: 2 * cmds.len}

	for cmd in cmds {
		out << "echo -e '+ ${escape_shell_string(cmd)}'"
		out << cmd
	}

	return out
}

// create_build_script generates a shell script that builds a given Target.
fn create_build_script(address string, config BuildConfig, build_arch string) string {
	repo_url := '$address/$config.repo'

	mut commands := [
		// This will later be replaced by a proper setting for changing the
		// mirrorlist
		"echo -e '[$config.repo]\\nServer = $address/\$repo/\$arch\\nSigLevel = Optional' >> /etc/pacman.conf"
		// We need to update the package list of the repo we just added above.
		// This should however not pull in a lot of packages as long as the
		// builder image is rebuilt frequently.
		'pacman -Syu --needed --noconfirm',
		// makepkg can't run as root
		'su builder',
	]

	commands << match config.kind {
		'git' {
			if config.branch == '' {
				[
					"git clone --single-branch --depth 1 '$config.url' repo",
				]
			} else {
				[
					"git clone --single-branch --depth 1 --branch $config.branch '$config.url' repo",
				]
			}
		}
		'url' {
			[
				'mkdir repo',
				"curl -o repo/PKGBUILD -L '$config.url'",
			]
		}
		else {
			panic("Invalid kind. This shouldn't be possible.")
		}
	}

	commands << if config.path != '' {
		"cd 'repo/$config.path'"
	} else {
		'cd repo'
	}

	commands << [
		'makepkg --nobuild --syncdeps --needed --noconfirm',
		'source PKGBUILD',
	]

	if !config.force {
		// The build container checks whether the package is already present on
		// the server.
		commands << [
			'curl -s --head --fail $repo_url/$build_arch/\$pkgname-\$pkgver-\$pkgrel && exit 0',
			// If the above curl command succeeds, we don't need to rebuild the
			// package. However, because we're in a su shell, the exit command will
			// drop us back into the root shell. Therefore, we must check whether
			// we're in root so we don't proceed.
			'[ "\$(id -u)" == 0 ] && exit 0',
		]
	}

	commands << [
		'MAKEFLAGS="-j\$(nproc)" makepkg -s --noconfirm --needed --noextract && for pkg in \$(ls -1 *.pkg*); do curl -XPOST -T "\$pkg" -H "X-API-KEY: \$API_KEY" $repo_url/publish; done',
	]

	return echo_commands(commands).join('\n')
}
