module main

import os
import server
import cli
import build
import git
import cron

fn main() {
	mut app := cli.Command{
		name: 'vieter'
		description: 'Vieter is a lightweight implementation of an Arch repository server.'
		version: '0.2.0'
		flags: [
			cli.Flag{
				flag: cli.FlagType.string
				name: 'config-file'
				abbrev: 'f'
				description: 'Location of Vieter config file; defaults to ~/.vieterrc.'
				global: true
				default_value: [os.expand_tilde_to_home('~/.vieterrc')]
			},
		]
		commands: [
			server.cmd(),
			build.cmd(),
			git.cmd(),
			cron.cmd(),
		]
	}

	app.setup()
	app.parse(os.args)
}
