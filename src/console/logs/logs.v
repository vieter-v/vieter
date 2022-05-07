module logs

import cli
import env
import client
import db

struct Config {
	address string [required]
	api_key string [required]
}

// cmd returns the cli module that handles the build repos API.
pub fn cmd() cli.Command {
	return cli.Command{
		name: 'logs'
		description: 'Interact with the build logs API.'
		commands: [
			cli.Command{
				name: 'list'
				description: 'List the build logs. If a repo ID is provided, only list the build logs for that repo.'
				flags: [
					cli.Flag{
						name: 'repo'
						description: 'ID of the Git repo to restrict list to.'
						flag: cli.FlagType.int
					},
				]
				execute: fn (cmd cli.Command) ? {
					config_file := cmd.flags.get_string('config-file') ?
					conf := env.load<Config>(config_file) ?

					repo_id := cmd.flags.get_int('repo') ?

					if repo_id == 0 { list(conf) ? } else { list_for_repo(conf, repo_id) ? }
				}
			},
			cli.Command{
				name: 'info'
				required_args: 1
				usage: 'id'
				description: 'Show all info for a specific build log.'
				execute: fn (cmd cli.Command) ? {
					config_file := cmd.flags.get_string('config-file') ?
					conf := env.load<Config>(config_file) ?

					id := cmd.args[0].int()
					info(conf, id) ?
				}
			},
			cli.Command{
				name: 'content'
				required_args: 1
				usage: 'id'
				description: 'Output the content of a build log to stdout.'
				execute: fn (cmd cli.Command) ? {
					config_file := cmd.flags.get_string('config-file') ?
					conf := env.load<Config>(config_file) ?

					id := cmd.args[0].int()
					content(conf, id) ?
				}
			},
		]
	}
}

// print_log_list prints a list of logs.
fn print_log_list(logs []db.BuildLog) {
	for log in logs {
		println('$log.id\t$log.start_time\t$log.exit_code')
	}
}

// list prints a list of all build logs.
fn list(conf Config) ? {
	c := client.new(conf.address, conf.api_key)
	logs := c.get_build_logs() ?.data

	print_log_list(logs)
}

// list prints a list of all build logs for a given repo.
fn list_for_repo(conf Config, repo_id int) ? {
	c := client.new(conf.address, conf.api_key)
	logs := c.get_build_logs_for_repo(repo_id) ?.data

	print_log_list(logs)
}

// info print the detailed info for a given build log.
fn info(conf Config, id int) ? {
	c := client.new(conf.address, conf.api_key)
	log := c.get_build_log(id) ?.data

	print(log)
}

// content outputs the contents of the log file for a given build log to
// stdout.
fn content(conf Config, id int) ? {
	c := client.new(conf.address, conf.api_key)
	content := c.get_build_log_content(id) ?

	println(content)
}
