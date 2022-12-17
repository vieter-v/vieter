module agent

import cli
import conf as vconf

struct Config {
pub:
	log_level string = 'WARN'
	// Architecture that the agent represents
	arch                    string
	api_key                 string
	address                 string
	data_dir                string
	max_concurrent_builds   int = 1
	polling_frequency       int = 30
	image_rebuild_frequency int = 1440
}

// cmd returns the cli module that handles the cron daemon.
pub fn cmd() cli.Command {
	return cli.Command{
		name: 'agent'
		description: 'Start an agent daemon.'
		execute: fn (cmd cli.Command) ! {
			config_file := cmd.flags.get_string('config-file')!
			conf := vconf.load<Config>(prefix: 'VIETER_', default_path: config_file)!

			agent(conf)!
		}
	}
}
