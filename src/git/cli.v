module git

import cli
import env
import net.http

struct Config {
	address string [required]
	api_key string [required]
}

pub fn cmd() cli.Command {
	return cli.Command{
		name: 'repos'
		description: 'Interact with the repos API.'
		commands: [
			cli.Command{
				name: 'list'
				description: 'List the current repos.'
				execute: fn (cmd cli.Command) ? {
					conf := env.load<Config>() ?

					list(conf) ?
				}
			},
		]
	}
}

fn list(conf Config) ? {
	mut req := http.new_request(http.Method.get, '$conf.address/api/repos', '') ?
	req.add_custom_header('X-API-Key', conf.api_key) ?

	res := req.do() ?

	println(res.text)
}
