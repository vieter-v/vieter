module server

import cli
import env

pub fn cmd() cli.Command {
	return cli.Command{
		name: 'server'
		description: 'Start the Vieter server'
		execute: fn (cmd cli.Command) ? {
			config_file := cmd.flags.get_string('config-file') ?
			conf := env.load<env.ServerConfig>(config_file) ?

			server(conf) ?
		}
	}
}
