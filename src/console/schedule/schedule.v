module schedule

import cli
import cron
import time

// cmd returns the cli submodule for previewing a cron schedule.
pub fn cmd() cli.Command {
	return cli.Command{
		name: 'schedule'
		usage: 'schedule'
		description: 'Preview the behavior of a cron schedule.'
		flags: [
			cli.Flag{
				name: 'count'
				description: 'How many scheduled times to show.'
				flag: cli.FlagType.int
				default_value: ['5']
			},
		]
		execute: fn (cmd cli.Command) ! {
			ce := cron.parse_expression(cmd.args.join(' '))!
			count := cmd.flags.get_int('count')!

			for t in ce.next_n(time.now(), count) {
				println(t)
			}
		}
	}
}
