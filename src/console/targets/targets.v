module targets

import cli
import conf as vconf
import cron.expression { parse_expression }
import client { NewTarget }
import console
import models { TargetFilter }

struct Config {
	address    string [required]
	api_key    string [required]
	base_image string = 'archlinux:base-devel'
}

// cmd returns the cli submodule that handles the repos API interaction
pub fn cmd() cli.Command {
	return cli.Command{
		name: 'targets'
		description: 'Interact with the targets API.'
		commands: [
			cli.Command{
				name: 'list'
				description: 'List the current targets.'
				flags: [
					cli.Flag{
						name: 'limit'
						description: 'How many results to return.'
						flag: cli.FlagType.int
					},
					cli.Flag{
						name: 'offset'
						description: 'Minimum index to return.'
						flag: cli.FlagType.int
					},
					cli.Flag{
						name: 'repo'
						description: 'Only return targets that publish to this repo.'
						flag: cli.FlagType.string
					},
				]
				execute: fn (cmd cli.Command) ! {
					config_file := cmd.flags.get_string('config-file')!
					conf := vconf.load<Config>(prefix: 'VIETER_', default_path: config_file)!

					mut filter := TargetFilter{}

					limit := cmd.flags.get_int('limit')!
					if limit != 0 {
						filter.limit = u64(limit)
					}

					offset := cmd.flags.get_int('offset')!
					if offset != 0 {
						filter.offset = u64(offset)
					}

					repo := cmd.flags.get_string('repo')!
					if repo != '' {
						filter.repo = repo
					}

					raw := cmd.flags.get_bool('raw')!

					list(conf, filter, raw)!
				}
			},
			cli.Command{
				name: 'add'
				required_args: 2
				usage: 'url repo'
				description: 'Add a new target with the given URL & target repo.'
				flags: [
					cli.Flag{
						name: 'kind'
						description: "Kind of target to add. Defaults to 'git' if not specified. One of 'git', 'url'."
						flag: cli.FlagType.string
						default_value: ['git']
					},
					cli.Flag{
						name: 'branch'
						description: "Which branch to clone; only applies to kind 'git'."
						flag: cli.FlagType.string
					},
				]
				execute: fn (cmd cli.Command) ! {
					config_file := cmd.flags.get_string('config-file')!
					conf := vconf.load<Config>(prefix: 'VIETER_', default_path: config_file)!

					t := NewTarget{
						kind: cmd.flags.get_string('kind')!
						url: cmd.args[0]
						repo: cmd.args[1]
						branch: cmd.flags.get_string('branch') or { '' }
					}

					raw := cmd.flags.get_bool('raw')!

					add(conf, t, raw)!
				}
			},
			cli.Command{
				name: 'remove'
				required_args: 1
				usage: 'id'
				description: 'Remove a target that matches the given id.'
				execute: fn (cmd cli.Command) ! {
					config_file := cmd.flags.get_string('config-file')!
					conf := vconf.load<Config>(prefix: 'VIETER_', default_path: config_file)!

					remove(conf, cmd.args[0])!
				}
			},
			cli.Command{
				name: 'info'
				required_args: 1
				usage: 'id'
				description: 'Show detailed information for the target matching the id.'
				execute: fn (cmd cli.Command) ! {
					config_file := cmd.flags.get_string('config-file')!
					conf := vconf.load<Config>(prefix: 'VIETER_', default_path: config_file)!

					info(conf, cmd.args[0])!
				}
			},
			cli.Command{
				name: 'edit'
				required_args: 1
				usage: 'id'
				description: 'Edit the target that matches the given id.'
				flags: [
					cli.Flag{
						name: 'url'
						description: 'URL value. Meaning depends on kind of target.'
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
					cli.Flag{
						name: 'kind'
						description: 'Kind of target.'
						flag: cli.FlagType.string
					},
				]
				execute: fn (cmd cli.Command) ! {
					config_file := cmd.flags.get_string('config-file')!
					conf := vconf.load<Config>(prefix: 'VIETER_', default_path: config_file)!

					found := cmd.flags.get_all_found()

					mut params := map[string]string{}

					for f in found {
						if f.name != 'config-file' {
							params[f.name] = f.get_string()!
						}
					}

					patch(conf, cmd.args[0], params)!
				}
			},
			cli.Command{
				name: 'build'
				required_args: 1
				usage: 'id'
				description: 'Build the target with the given id & publish it.'
				execute: fn (cmd cli.Command) ! {
					config_file := cmd.flags.get_string('config-file')!
					conf := vconf.load<Config>(prefix: 'VIETER_', default_path: config_file)!

					build(conf, cmd.args[0].int())!
				}
			},
		]
	}
}

// get_repo_by_prefix tries to find the repo with the given prefix in its
// ID. If multiple or none are found, an error is raised.

// list prints out a list of all repositories.
fn list(conf Config, filter TargetFilter, raw bool) ! {
	c := client.new(conf.address, conf.api_key)
	repos := c.get_targets(filter)!
	data := repos.map([it.id.str(), it.kind, it.url, it.repo])

	if raw {
		println(console.tabbed_table(data))
	} else {
		println(console.pretty_table(['id', 'kind', 'url', 'repo'], data)!)
	}
}

// add adds a new repository to the server's list.
fn add(conf Config, t &NewTarget, raw bool) ! {
	c := client.new(conf.address, conf.api_key)
	res := c.add_target(t)!

	if raw {
		println(res.data)
	} else {
		println('Target added with id $res.data')
	}
}

// remove removes a repository from the server's list.
fn remove(conf Config, id string) ! {
	id_int := id.int()

	if id_int != 0 {
		c := client.new(conf.address, conf.api_key)
		c.remove_target(id_int)!
	}
}

// patch patches a given repository with the provided params.
fn patch(conf Config, id string, params map[string]string) ! {
	// We check the cron expression first because it's useless to send an
	// invalid one to the server.
	if 'schedule' in params && params['schedule'] != '' {
		parse_expression(params['schedule']) or {
			return error('Invalid cron expression: $err.msg()')
		}
	}

	id_int := id.int()
	if id_int != 0 {
		c := client.new(conf.address, conf.api_key)
		c.patch_target(id_int, params)!
	}
}

// info shows detailed information for a given repo.
fn info(conf Config, id string) ! {
	id_int := id.int()

	if id_int == 0 {
		return
	}

	c := client.new(conf.address, conf.api_key)
	repo := c.get_target(id_int)!
	println(repo)
}
