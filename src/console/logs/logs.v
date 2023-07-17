module logs

import cli
import conf as vconf
import client
import console
import time
import models { BuildLog, BuildLogFilter }

struct Config {
	address string [required]
	api_key string [required]
}

// cmd returns the cli module that handles the build logs API.
pub fn cmd() cli.Command {
	return cli.Command{
		name: 'logs'
		description: 'Interact with the build logs API.'
		commands: [
			cli.Command{
				name: 'list'
				description: 'List build logs. All date strings in the output are converted to the local timezone. Any time strings provided as input should be in the local timezone as well.'
				flags: [
					cli.Flag{
						name: 'limit'
						abbrev: 'l'
						description: 'How many results to return.'
						flag: cli.FlagType.int
					},
					cli.Flag{
						name: 'offset'
						abbrev: 'o'
						description: 'Minimum index to return.'
						flag: cli.FlagType.int
					},
					cli.Flag{
						name: 'target'
						description: 'Only return logs for this target id.'
						flag: cli.FlagType.int
					},
					cli.Flag{
						name: 'today'
						abbrev: 't'
						description: 'Only list logs started today. This flag overwrites any other date-related flag.'
						flag: cli.FlagType.bool
					},
					cli.Flag{
						name: 'failed'
						description: 'Only list logs with non-zero exit codes. This flag overwrites the --code flag.'
						flag: cli.FlagType.bool
					},
					cli.Flag{
						name: 'day'
						abbrev: 'd'
						description: 'Only list logs started on this day. (format: YYYY-MM-DD)'
						flag: cli.FlagType.string
					},
					cli.Flag{
						name: 'before'
						description: 'Only list logs started before this timestamp. (format: YYYY-MM-DD HH:mm:ss)'
						flag: cli.FlagType.string
					},
					cli.Flag{
						name: 'after'
						description: 'Only list logs started after this timestamp. (format: YYYY-MM-DD HH:mm:ss)'
						flag: cli.FlagType.string
					},
					cli.Flag{
						name: 'code'
						description: 'Only return logs with the given exit code. Prepend with `!` to exclude instead of include. Can be specified multiple times.'
						flag: cli.FlagType.string_array
					},
				]
				execute: fn (cmd cli.Command) ! {
					config_file := cmd.flags.get_string('config-file')!
					conf_ := vconf.load[Config](prefix: 'VIETER_', default_path: config_file)!

					mut filter := BuildLogFilter{}

					limit := cmd.flags.get_int('limit')!
					if limit != 0 {
						filter.limit = u64(limit)
					}

					offset := cmd.flags.get_int('offset')!
					if offset != 0 {
						filter.offset = u64(offset)
					}

					target_id := cmd.flags.get_int('target')!
					if target_id != 0 {
						filter.target = target_id
					}

					tz_offset := time.offset()

					if cmd.flags.get_bool('today')! {
						today := time.now()

						filter.after = time.new_time(time.Time{
							year: today.year
							month: today.month
							day: today.day
						}).add_seconds(-tz_offset)
						filter.before = filter.after.add_days(1)
					}
					// The -today flag overwrites any of the other date flags.
					else {
						day_str := cmd.flags.get_string('day')!
						before_str := cmd.flags.get_string('before')!
						after_str := cmd.flags.get_string('after')!

						if day_str != '' {
							day := time.parse_rfc3339(day_str)!
							day_utc := time.new_time(time.Time{
								year: day.year
								month: day.month
								day: day.day
							}).add_seconds(-tz_offset)

							// The extra -1 is so we also return logs that
							// started at exactly midnight (filter bounds are
							// exclusive). therefore, we have to request logs
							// started after 23:59:59 the previous day.
							filter.after = day_utc.add_seconds(-1)
							filter.before = day_utc.add_days(1)
						} else {
							if before_str != '' {
								filter.before = time.parse(before_str)!.add_seconds(-tz_offset)
							}

							if after_str != '' {
								filter.after = time.parse(after_str)!.add_seconds(-tz_offset)
							}
						}
					}

					if cmd.flags.get_bool('failed')! {
						filter.exit_codes = [
							'!0',
						]
					} else {
						filter.exit_codes = cmd.flags.get_strings('code')!
					}

					raw := cmd.flags.get_bool('raw')!

					list(conf_, filter, raw)!
				}
			},
			cli.Command{
				name: 'remove'
				required_args: 1
				usage: 'id'
				description: 'Remove a build log that matches the given id.'
				execute: fn (cmd cli.Command) ! {
					config_file := cmd.flags.get_string('config-file')!
					conf_ := vconf.load[Config](prefix: 'VIETER_', default_path: config_file)!

					remove(conf_, cmd.args[0])!
				}
			},
			cli.Command{
				name: 'info'
				required_args: 1
				usage: 'id'
				description: 'Show all info for a specific build log.'
				execute: fn (cmd cli.Command) ! {
					config_file := cmd.flags.get_string('config-file')!
					conf_ := vconf.load[Config](prefix: 'VIETER_', default_path: config_file)!

					id := cmd.args[0].int()
					info(conf_, id)!
				}
			},
			cli.Command{
				name: 'content'
				required_args: 1
				usage: 'id'
				description: 'Output the content of a build log to stdout.'
				execute: fn (cmd cli.Command) ! {
					config_file := cmd.flags.get_string('config-file')!
					conf_ := vconf.load[Config](prefix: 'VIETER_', default_path: config_file)!

					id := cmd.args[0].int()
					content(conf_, id)!
				}
			},
		]
	}
}

// print_log_list prints a list of logs.
fn print_log_list(logs []BuildLog, raw bool) ! {
	data := logs.map([it.id.str(), it.target_id.str(), it.start_time.local().str(),
		it.exit_code.str()])

	if raw {
		println(console.tabbed_table(data))
	} else {
		println(console.pretty_table(['id', 'target', 'start time', 'exit code'], data)!)
	}
}

// list prints a list of all build logs.
fn list(conf_ Config, filter BuildLogFilter, raw bool) ! {
	c := client.new(conf_.address, conf_.api_key)
	logs := c.get_build_logs(filter)!

	print_log_list(logs, raw)!
}

// info print the detailed info for a given build log.
fn info(conf_ Config, id int) ! {
	c := client.new(conf_.address, conf_.api_key)
	log := c.get_build_log(id)!

	print(log)
}

// content outputs the contents of the log file for a given build log to
// stdout.
fn content(conf_ Config, id int) ! {
	c := client.new(conf_.address, conf_.api_key)
	content := c.get_build_log_content(id)!

	println(content)
}

// remove removes a build log from the server's list.
fn remove(conf_ Config, id string) ! {
	c := client.new(conf_.address, conf_.api_key)
	c.remove_build_log(id.int())!
}
