module aur

import cli
import console
import client
import aur
import conf as vconf

struct Config {
	address string [required]
	api_key string [required]
}

// cmd returns the cli module for interacting with the AUR API.
pub fn cmd() cli.Command {
	return cli.Command{
		name: 'aur'
		description: 'Interact with the AUR.'
		commands: [
			cli.Command{
				name: 'search'
				description: 'Search for packages.'
				required_args: 1
				execute: fn (cmd cli.Command) ! {
					c := aur.new()
					pkgs := c.search(cmd.args[0])!
					data := pkgs.map([it.name, it.description])

					println(console.pretty_table(['name', 'description'], data)!)
				}
			},
			cli.Command{
				name: 'add'
				usage: 'repo pkg-name [pkg-name...]'
				description: 'Add the given AUR package(s) to Vieter. Non-existent packages will be silently ignored.'
				required_args: 2
				execute: fn (cmd cli.Command) ! {
					config_file := cmd.flags.get_string('config-file')!
					conf_ := vconf.load[Config](prefix: 'VIETER_', default_path: config_file)!

					c := aur.new()
					pkgs := c.info(cmd.args[1..])!

					vc := client.new(conf_.address, conf_.api_key)

					for pkg in pkgs {
						vc.add_target(
							kind: 'git'
							url: 'https://aur.archlinux.org/${pkg.package_base}' + '.git'
							repo: cmd.args[0]
						) or {
							println('Failed to add ${pkg.name}: ${err.msg()}')
							continue
						}

						println('Added ${pkg.name}' + '.')
					}
				}
			},
		]
	}
}
