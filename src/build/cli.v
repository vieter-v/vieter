module build

import cli
import env

// cmd returns the cli submodule that handles the build process
pub fn cmd() cli.Command {
	return cli.Command{
		name: 'build'
		description: 'Run the build process.'
		execute: fn (cmd cli.Command) ? {
			config_file := cmd.flags.get_string('config-file') ?
			conf := env.load<env.BuildConfig>(config_file) ?

			build(conf) ?
		}
	}
}
