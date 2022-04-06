module build

import cli
import env

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
