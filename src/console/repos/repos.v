module repos

import cli
import conf as vconf
import client

struct Config {
	address string [required]
	api_key string [required]
}

// cmd returns the cli module that handles modifying the repository contents.
pub fn cmd() cli.Command {
	return cli.Command{
		name: 'repos'
		description: 'Interact with the repositories & packages stored on the server.'
		commands: [
			cli.Command{
				name: 'remove'
				required_args: 1
				usage: 'repo [arch [pkgname]]'
				description: 'Remove a repo, arch-repo, or package from the server.'
				flags: [
					cli.Flag{
						name: 'force'
						flag: cli.FlagType.bool
					},
				]
				execute: fn (cmd cli.Command) ! {
					config_file := cmd.flags.get_string('config-file')!
					conf := vconf.load<Config>(prefix: 'VIETER_', default_path: config_file)!

					if cmd.args.len < 3 {
						if !cmd.flags.get_bool('force')! {
							return error('Removing an arch-repo or repository is a very destructive command. If you really do wish to perform this operation, explicitely add the --force flag.')
						}
					}

					client := client.new(conf.address, conf.api_key)

					if cmd.args.len == 1 {
						client.remove_repo(cmd.args[0])!
					} else if cmd.args.len == 2 {
						client.remove_arch_repo(cmd.args[0], cmd.args[1])!
					} else {
						client.remove_package(cmd.args[0], cmd.args[1], cmd.args[2])!
					}
				}
			},
		]
	}
}
