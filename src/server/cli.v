module server

import cli
import env

pub fn cmd() cli.Command {
	return cli.Command{
		name: 'server'
		description: 'Start the Vieter server'
		execute: fn (cmd cli.Command) ? {
			conf := env.load<env.ServerConfig>() ?

			server.server(conf) ?
		}
	}
}
