module agent

import log
import os

const log_file_name = 'vieter.agent.log'

// agent start an agent service
pub fn agent(conf Config) ! {
	// Configure logger
	log_level := log.level_from_tag(conf.log_level) or {
		return error('Invalid log level. The allowed values are FATAL, ERROR, WARN, INFO & DEBUG.')
	}

	mut logger := log.Log{
		level: log_level
	}

	log_file := os.join_path_single(conf.data_dir, agent.log_file_name)
	logger.set_full_logpath(log_file)
	logger.log_to_console_too()

	mut d := agent_init(logger, conf)
	d.run()
}
