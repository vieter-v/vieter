module server

import cli
import env

struct Config {
pub:
	log_level    string = 'WARN'
	log_file     string = 'vieter.log'
	pkg_dir      string
	download_dir string
	api_key      string
	repos_dir     string
	repos_file   string
	default_arch string
}

// cmd returns the cli submodule that handles starting the server
pub fn cmd() cli.Command {
	return cli.Command{
		name: 'server'
		description: 'Start the Vieter server.'
		execute: fn (cmd cli.Command) ? {
			config_file := cmd.flags.get_string('config-file') ?
			conf := env.load<Config>(config_file) ?

			server(conf) ?
		}
	}
}
