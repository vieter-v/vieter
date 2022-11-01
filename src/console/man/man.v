module man

import cli
import console
import os

// cmd returns the cli submodule that handles generating man pages.
pub fn cmd() cli.Command {
	return cli.Command{
		name: 'man'
		description: 'Generate all man pages & save them in the given directory.'
		usage: 'dir'
		required_args: 1
		execute: fn (cmd cli.Command) ! {
			root := cmd.root()
			os.mkdir_all(cmd.args[0])!

			console.export_man_pages(root, cmd.args[0])!
		}
	}
}
