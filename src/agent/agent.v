module agent

import log
import os
import util

const log_file_name = 'vieter.agent.log'

// agent starts an agent service
pub fn agent(conf Config) ! {
	log_level := log.level_from_tag(conf.log_level) or {
		return error('Invalid log level. The allowed values are FATAL, ERROR, WARN, INFO & DEBUG.')
	}

	mut logger := log.Log{
		level: log_level
	}

	os.mkdir_all(conf.data_dir) or { util.exit_with_message(1, 'Failed to create data directory.') }

	log_file := os.join_path_single(conf.data_dir, agent.log_file_name)
	logger.set_full_logpath(log_file)
	logger.log_to_console_too()

	mut d := agent_init(logger, conf)
	d.run()
}
