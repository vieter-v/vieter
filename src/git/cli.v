module git

import cli
import env

struct Config {
	address string [required]
	api_key string [required]
}

// cmd returns the cli submodule that handles the repos API interaction
pub fn cmd() cli.Command {
	return cli.Command{
		name: 'repos'
		description: 'Interact with the repos API.'
		commands: [
			cli.Command{
				name: 'list'
				description: 'List the current repos.'
				execute: fn (cmd cli.Command) ? {
					config_file := cmd.flags.get_string('config-file') ?
					conf := env.load<Config>(config_file) ?

					list(conf) ?
				}
			},
			cli.Command{
				name: 'add'
				required_args: 2
				usage: 'url branch arch...'
				description: 'Add a new repository.'
				execute: fn (cmd cli.Command) ? {
					config_file := cmd.flags.get_string('config-file') ?
					conf := env.load<Config>(config_file) ?

					add(conf, cmd.args[0], cmd.args[1], cmd.args[2..]) ?
				}
			},
			cli.Command{
				name: 'remove'
				required_args: 1
				usage: 'id'
				description: 'Remove a repository that matches the given ID prefix.'
				execute: fn (cmd cli.Command) ? {
					config_file := cmd.flags.get_string('config-file') ?
					conf := env.load<Config>(config_file) ?

					remove(conf, cmd.args[0]) ?
				}
			},
		]
	}
}

fn list(conf Config) ? {
	repos := get_repos(conf.address, conf.api_key) ?

	for id, details in repos {
		println('${id[..8]}\t$details.url\t$details.branch\t$details.arch')
	}
}

fn add(conf Config, url string, branch string, arch []string) ? {
	res := add_repo(conf.address, conf.api_key, url, branch, arch) ?

	println(res.message)
}

fn remove(conf Config, id_prefix string) ? {
	repos := get_repos(conf.address, conf.api_key) ?

	mut to_remove := []string{}

	for id, _ in repos {
		if id.starts_with(id_prefix) {
			to_remove << id
		}
	}

	if to_remove.len == 0 {
		eprintln('No repo found for given prefix.')
		exit(1)
	}

	if to_remove.len > 1 {
		eprintln('Multiple repos found for given prefix.')
		exit(1)
	}

	res := remove_repo(conf.address, conf.api_key, to_remove[0]) ?

	println(res.message)
}
