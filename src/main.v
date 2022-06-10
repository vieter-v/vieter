module main

import os
import server
import cli
import console.git
import console.logs
import console.schedule
import console.man
import cron

fn main() {
	mut app := cli.Command{
		name: 'vieter'
		description: 'Vieter is a lightweight implementation of an Arch repository server.'
		version: '0.3.0-rc.1'
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
			git.cmd(),
			cron.cmd(),
			logs.cmd(),
			schedule.cmd(),
			man.cmd(),
		]
	}
	app.setup()
	app.parse(os.args)
	return
}
