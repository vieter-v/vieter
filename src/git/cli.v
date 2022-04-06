module git

import cli
import env
import net.http
import json
import git
import response

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
				required_args: 2
				usage: 'url branch'
				description: 'Remove a repository.'
				execute: fn (cmd cli.Command) ? {
					config_file := cmd.flags.get_string('config-file') ?
					conf := env.load<Config>(config_file) ?

					remove(conf, cmd.args[0], cmd.args[1]) ?
				}
			},
		]
	}
}

fn list(conf Config) ? {
	mut req := http.new_request(http.Method.get, '$conf.address/api/repos', '') ?
	req.add_custom_header('X-API-Key', conf.api_key) ?

	res := req.do() ?
	data := json.decode(response.Response<map[string]git.GitRepo>, res.text) ?

	for id, details in data.data {
		println("${id[..8]}\t$details.url\t$details.branch\t$details.arch")
	}
}

fn add(conf Config, url string, branch string, arch []string) ? {
	mut req := http.new_request(http.Method.post, '$conf.address/api/repos?url=$url&branch=$branch&arch=${arch.join(',')}',
		'') ?
	req.add_custom_header('X-API-Key', conf.api_key) ?

	res := req.do() ?

	println(res.text)
}

fn remove(conf Config, url string, branch string) ? {
	mut req := http.new_request(http.Method.delete, '$conf.address/api/repos?url=$url&branch=$branch',
		'') ?
	req.add_custom_header('X-API-Key', conf.api_key) ?

	res := req.do() ?

	println(res.text)
}
