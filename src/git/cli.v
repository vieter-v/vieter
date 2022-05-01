module git

import cli
import env
import cron.expression { parse_expression }

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
				required_args: 3
				usage: 'url branch repo'
				description: 'Add a new repository.'
				execute: fn (cmd cli.Command) ? {
					config_file := cmd.flags.get_string('config-file') ?
					conf := env.load<Config>(config_file) ?

					add(conf, cmd.args[0], cmd.args[1], cmd.args[2]) ?
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
				name: 'info'
				required_args: 1
				usage: 'id'
				description: 'Show detailed information for the repo matching the ID prefix.'
				execute: fn (cmd cli.Command) ? {
					config_file := cmd.flags.get_string('config-file') ?
					conf := env.load<Config>(config_file) ?

					info(conf, cmd.args[0]) ?
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
					cli.Flag{
						name: 'schedule'
						description: 'Cron schedule for repository.'
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

// get_repo_by_prefix tries to find the repo with the given prefix in its
// ID. If multiple or none are found, an error is raised.
fn get_repo_by_prefix(conf Config, id_prefix string) ?(string, GitRepo) {
	repos := get_repos(conf.address, conf.api_key) ?

	mut res := map[string]GitRepo{}

	for id, repo in repos {
		if id.starts_with(id_prefix) {
			res[id] = repo
		}
	}

	if res.len == 0 {
		return error('No repo found for given prefix.')
	}

	if res.len > 1 {
		return error('Multiple repos found for given prefix.')
	}

	return res.keys()[0], res[res.keys()[0]]
}

// list prints out a list of all repositories.
fn list(conf Config) ? {
	repos := get_repos(conf.address, conf.api_key) ?

	for id, details in repos {
		println('${id[..8]}\t$details.url\t$details.branch\t$details.repo')
	}
}

// add adds a new repository to the server's list.
fn add(conf Config, url string, branch string, repo string) ? {
	res := add_repo(conf.address, conf.api_key, url, branch, repo, []) ?

	println(res.message)
}

// remove removes a repository from the server's list.
fn remove(conf Config, id_prefix string) ? {
	id, _ := get_repo_by_prefix(conf, id_prefix) ?
	res := remove_repo(conf.address, conf.api_key, id) ?

	println(res.message)
}

// patch patches a given repository with the provided params.
fn patch(conf Config, id_prefix string, params map[string]string) ? {
	// We check the cron expression first because it's useless to send an
	// invalid one to the server.
	if 'schedule' in params && params['schedule'] != '' {
		parse_expression(params['schedule']) or {
			return error('Invalid cron expression: $err.msg()')
		}
	}

	id, _ := get_repo_by_prefix(conf, id_prefix) ?
	res := patch_repo(conf.address, conf.api_key, id, params) ?

	println(res.message)
}

// info shows detailed information for a given repo.
fn info(conf Config, id_prefix string) ? {
	id, repo := get_repo_by_prefix(conf, id_prefix) ?

	println('id: $id')

	$for field in GitRepo.fields {
		val := repo.$(field.name)
		println('$field.name: $val')
	}
}
