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
				required_args: 4
				usage: 'url branch repo arch...'
				description: 'Add a new repository.'
				execute: fn (cmd cli.Command) ? {
					config_file := cmd.flags.get_string('config-file') ?
					conf := env.load<Config>(config_file) ?

					add(conf, cmd.args[0], cmd.args[1], cmd.args[2], cmd.args[3..]) ?
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
			cli.Command{
				name: 'edit'
				required_args: 1
				usage: 'id'
				description: 'Edit the repository that matches the given ID prefix.'
				flags: [
					cli.Flag{
						name: 'url'
						description: 'URL of the Git repository.'
						flag: cli.FlagType.string
					},
					cli.Flag{
						name: 'branch'
						description: 'Branch of the Git repository.'
						flag: cli.FlagType.string
					},
					cli.Flag{
						name: 'repo'
						description: 'Repo to publish builds to.'
						flag: cli.FlagType.string
					},
					cli.Flag{
						name: 'arch'
						description: 'Comma-separated list of architectures to build on.'
						flag: cli.FlagType.string
					},
				]
				execute: fn (cmd cli.Command) ? {
					config_file := cmd.flags.get_string('config-file') ?
					conf := env.load<Config>(config_file) ?

					found := cmd.flags.get_all_found()

					mut params := map[string]string{}

					for f in found {
						if f.name != 'config-file' {
							params[f.name] = f.get_string() ?
						}
					}

					patch(conf, cmd.args[0], params) ?
				}
			},
		]
	}
}

// get_repo_id_by_prefix tries to find the repo with the given prefix in its
// ID. If multiple or none are found, an error is raised.
fn get_repo_id_by_prefix(conf Config, id_prefix string) ?string {
	repos := get_repos(conf.address, conf.api_key) ?

	mut res := []string{}

	for id, _ in repos {
		if id.starts_with(id_prefix) {
			res << id
		}
	}

	if res.len == 0 {
		return error('No repo found for given prefix.')
	}

	if res.len > 1 {
		return error('Multiple repos found for given prefix.')
	}

	return res[0]
}

// list prints out a list of all repositories.
fn list(conf Config) ? {
	repos := get_repos(conf.address, conf.api_key) ?

	for id, details in repos {
		println('${id[..8]}\t$details.url\t$details.branch\t$details.repo\t$details.arch')
	}
}

// add adds a new repository to the server's list.
fn add(conf Config, url string, branch string, repo string, arch []string) ? {
	res := add_repo(conf.address, conf.api_key, url, branch, repo, arch) ?

	println(res.message)
}

// remove removes a repository from the server's list.
fn remove(conf Config, id_prefix string) ? {
	id := get_repo_id_by_prefix(conf, id_prefix) ?
	res := remove_repo(conf.address, conf.api_key, id) ?

	println(res.message)
}

// patch patches a given repository with the provided params.
fn patch(conf Config, id_prefix string, params map[string]string) ? {
	id := get_repo_id_by_prefix(conf, id_prefix) ?
	res := patch_repo(conf.address, conf.api_key, id, params) ?

	println(res.message)
}
