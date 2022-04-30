module cron

import cli
import env

struct Config {
pub:
	log_level               string = 'WARN'
	log_file                string = 'vieter.log'
	api_key                 string
	address                 string
	base_image              string = 'archlinux:base-devel'
	max_concurrent_builds   int    = 1
	api_update_frequency    int    = 15
	image_rebuild_frequency int    = 1440
	// Replicates the behavior of the original cron system
	global_schedule string = '0 3'
}

// cmd returns the cli module that handles the cron daemon.
pub fn cmd() cli.Command {
	return cli.Command{
		name: 'cron'
		description: 'Start the cron service that periodically runs builds.'
		execute: fn (cmd cli.Command) ? {
			config_file := cmd.flags.get_string('config-file') ?
			conf := env.load<Config>(config_file) ?

			cron(conf) ?
		}
	}
}
