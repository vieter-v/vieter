import os
import toml
import net.http

struct Config {
	address string [required]
	api_key string [required]
}

fn list(conf Config) ? {
	mut req := http.new_request(http.Method.get, '$conf.address/api/repos', '') ?
	req.add_custom_header('X-API-Key', conf.api_key) ?

	res := req.do() ?

	println(res.text)
}

fn add(conf Config, args []string) ? {
	if args.len < 2 {
		eprintln('Not enough arguments.')
		exit(1)
	}

	if args.len > 2 {
		eprintln('Too many arguments.')
		exit(1)
	}

	mut req := http.new_request(http.Method.post, '$conf.address/api/repos?url=${args[0]}&branch=${args[1]}', '') ?
	req.add_custom_header('X-API-Key', conf.api_key) ?

	res := req.do() ?

	println(res.text)
}

fn remove(conf Config, args []string) ? {
	if args.len < 2 {
		eprintln('Not enough arguments.')
		exit(1)
	}

	if args.len > 2 {
		eprintln('Too many arguments.')
		exit(1)
	}

	mut req := http.new_request(http.Method.delete, '$conf.address/api/repos?url=${args[0]}&branch=${args[1]}', '') ?
	req.add_custom_header('X-API-Key', conf.api_key) ?

	res := req.do() ?

	println(res.text)
}

fn main() {
	conf_path := os.expand_tilde_to_home('~/.vieterrc')

	if !os.is_file(conf_path) {
		exit(1)
	}

	conf := toml.parse_file(conf_path) ?.reflect<Config>()

	args := os.args[1..]

	if args.len == 0 {
		eprintln('No action provided.')
		exit(1)
	}

	action := args[0]

	match action {
		'list' { list(conf) ? }
		'add' { add(conf, args[1..]) ? }
		'remove' { remove(conf, args[1..]) ? }
		else {
			eprintln("Invalid action '$action'.")
			exit(1)
		}
	}
}
