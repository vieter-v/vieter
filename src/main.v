module main

import os
import server
import cli
import console.targets
import console.logs
import console.schedule
import console.man
import console.aur
import console.repos
import agent

fn main() {
	// Stop buffering output so logs always show up immediately
	unsafe {
		C.setbuf(C.stdout, 0)
	}

	mut app := cli.Command{
		name: 'vieter'
		description: 'Vieter is a lightweight implementation of an Arch repository server.'
		version: '0.6.0'
		posix_mode: true
		flags: [
			cli.Flag{
				flag: cli.FlagType.string
				name: 'config-file'
				abbrev: 'f'
				description: 'Location of Vieter config file; defaults to ~/.vieterrc.'
				global: true
				default_value: [os.expand_tilde_to_home('~/.vieterrc')]
			},
			cli.Flag{
				flag: cli.FlagType.bool
				name: 'raw'
				abbrev: 'r'
				description: 'Only output minimal information (no formatted tables, etc.)'
				global: true
			},
		]
		commands: [
			server.cmd(),
			targets.cmd(),
			logs.cmd(),
			schedule.cmd(),
			man.cmd(),
			aur.cmd(),
			agent.cmd(),
			repos.cmd(),
		]
	}
	app.setup()
	app.parse(os.args)
	return
}
