module aur

import cli
import console
import vieter_v.aur

pub fn cmd() cli.Command {
	return cli.Command{
		name: 'aur'
		description: 'Interact with the AUR.'
		commands: [
			cli.Command{
				name: 'search'
				description: 'Search for packages.'
				required_args: 1
				execute: fn (cmd cli.Command) ? {
					c := aur.new()
					pkgs := c.search(cmd.args[0])?
					data := pkgs.map([it.name, it.description])

					println(console.pretty_table(['name', 'description'], data)?)
				}
			},
		]
	}
}
