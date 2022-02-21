module main

import os
import server
import util

fn main() {
	if os.args.len == 1 {
		util.exit_with_message(1, 'No action provided.')
	}

	match os.args[1] {
		'server' { server.server() ? }
		'build' { build() ? }
		else { util.exit_with_message(1, 'Unknown action: ${os.args[1]}') }
	}
}
