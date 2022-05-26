module schedule

import cli
import cron.expression { parse_expression }

// cmd returns the cli submodule for previewing a cron schedule.
pub fn cmd() cli.Command {
	return cli.Command{
		name: 'schedule'
		description: 'Preview the behavior of a cron schedule.'
		flags: [
			cli.Flag{
				name: 'count'
				description: 'How many scheduled times to show.'
				flag: cli.FlagType.int
				default_value: ['5']
			},
		]
		execute: fn (cmd cli.Command) ? {
			exp := parse_expression(cmd.args.join(' '))?

			mut t := exp.next_from_now()?
			println(t)

			count := cmd.flags.get_int('count')?

			for _ in 1 .. count {
				t = exp.next(t)?

				println(t)
			}
		}
	}
}
