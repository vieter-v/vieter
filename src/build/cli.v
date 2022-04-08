module build

import cli
import env

pub struct Config {
pub:
	api_key string
	address string
	base_image string = 'archlinux:base-devel'
}

// cmd returns the cli submodule that handles the build process
pub fn cmd() cli.Command {
	return cli.Command{
		name: 'build'
		description: 'Run the build process.'
		execute: fn (cmd cli.Command) ? {
			config_file := cmd.flags.get_string('config-file') ?
			conf := env.load<Config>(config_file) ?

			build(conf) ?
		}
	}
}
