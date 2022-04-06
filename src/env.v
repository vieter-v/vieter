module env

import os
import toml

// The prefix that every environment variable should have
const prefix = 'VIETER_'

// The suffix an environment variable in order for it to be loaded from a file
// instead
const file_suffix = '_FILE'

pub struct ServerConfig {
pub:
	log_level    string [default: WARN]
	log_file     string [default: 'vieter.log']
	pkg_dir      string
	download_dir string
	api_key      string
	repo_dir     string
	repos_file   string
}

pub struct BuildConfig {
pub:
	api_key string
	address string
}

fn get_env_var(field_name string) ?string {
	env_var_name := '$env.prefix$field_name.to_upper()'
	env_file_name := '$env.prefix$field_name.to_upper()$env.file_suffix'
	env_var := os.getenv(env_var_name)
	env_file := os.getenv(env_file_name)

	// If both are missing, we return an empty string
	if env_var == '' && env_file == '' {
		return ''
	}

	// If they're both set, we report a conflict
	if env_var != '' && env_file != '' {
		return error('Only one of $env_var_name or $env_file_name can be defined.')
	}

	// If it's the env var itself, we return it.
	// I'm pretty sure this also prevents variable ending in _FILE (e.g.
	// VIETER_LOG_FILE) from being mistakingely read as an _FILE suffixed env
	// var.
	if env_var != '' {
		return env_var
	}

	// Otherwise, we process the file
	return os.read_file(env_file) or {
		error('Failed to read file defined in $env_file_name: ${err.msg}.')
	}
}

// load<T> attempts to create the given type from environment variables. For
// each field, the corresponding env var is its name in uppercase prepended
// with the hardcoded prefix. If this one isn't present, it looks for the env
// var with the file_suffix suffix.
pub fn load<T>(path string) ?T {
	mut res := T{}

	if os.exists(path) {
		res = toml.parse_file(path) ?.reflect<T>()
	}

	$for field in T.fields {
		$if field.typ is string {
			env_value := get_env_var(field.name) ?

			// The value of the env var will always be chosen over the config
			// file
			if env_value != '' {
				res.$(field.name) = env_value
			}
			// If there's no value from the toml file either, we try to find a
			// default value
			else if res.$(field.name) == '' {
				// We use the default instead, if it's present
				mut default := ''

				for attr in field.attrs {
					if attr.starts_with('default: ') {
						default = attr[9..]
						break
					}
				}

				if default == '' {
					return error("Missing config variable '$field.name' with no provided default. Either add it to the config file or provide it using an environment variable.")
				}

				res.$(field.name) = default
			}
		}
	}
	return res
}
