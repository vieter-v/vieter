module server

import cli
import vieter.vconf

struct Config {
pub:
	log_level    string = 'WARN'
	pkg_dir      string
	data_dir     string
	api_key      string
	default_arch string
}

// cmd returns the cli submodule that handles starting the server
pub fn cmd() cli.Command {
	return cli.Command{
		name: 'server'
		description: 'Start the Vieter server.'
		execute: fn (cmd cli.Command) ? {
			config_file := cmd.flags.get_string('config-file')?
			conf := vconf.load<Config>(prefix: 'VIETER_', default_path: config_file)?

			server(conf)?
		}
	}
}
