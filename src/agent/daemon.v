module agent

import log
import sync.stdatomic
import build { BuildConfig }
import client

const (
	build_empty   = 0
	build_running = 1
	build_done    = 2
)

struct AgentDaemon {
	logger shared log.Log
	conf Config
	// Which builds are currently running; length is same as
	// conf.max_concurrent_builds
	builds []BuildConfig
	// Atomic variables used to detect when a build has finished; length is the
	// same as conf.max_concurrent_builds
	client                  client.Client
	atomics []u64
}

fn agent_init(logger log.Log, conf Config) AgentDaemon {
	mut d := AgentDaemon{
		logger: logger
		client: client.new(conf.address, conf.api_key)
		conf: conf
		builds: []BuildConfig{len: conf.max_concurrent_builds}
		atomics: []u64{len: conf.max_concurrent_builds}
	}

	return d
}

pub fn (mut d AgentDaemon) run() {
	for {
		free_builds := d.update_atomics()

	  if  free_builds > 0  {
		
	  }
		
	}
}

// clean_finished_builds checks for each build whether it's completed, and sets
// it to free again if so. The return value is how many fields are now set to
// free.
fn (mut d AgentDaemon) update_atomics() int {
	mut count := 0

	for i in 0 .. d.atomics.len {
		if stdatomic.load_u64(&d.atomics[i]) == agent.build_done {
			stdatomic.store_u64(&d.atomics[i], agent.build_empty)
			count++
		} else if stdatomic.load_u64(&d.atomics[i]) == agent.build_empty {
			count++
		}
	}

	return count
}
