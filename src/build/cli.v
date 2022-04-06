module build

import cli
import env

pub fn cmd() cli.Command {
	return cli.Command{
		name: 'build'
		description: 'Run the build process.'
		execute: fn (cmd cli.Command) ? {
			conf := env.load<env.BuildConfig>() ?

			build(conf) ?
		}
	}
}

