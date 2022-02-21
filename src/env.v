module env

import os

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
	api_key  string
	repo_dir string
	address  string
}

fn get_env_var(field_name string) ?string {
	env_var_name := '$env.prefix$field_name.to_upper()'
	env_file_name := '$env.prefix$field_name.to_upper()$env.file_suffix'
	env_var := os.getenv(env_var_name)
	env_file := os.getenv(env_file_name)

	// If both aren't set, we report them missing
	if env_var == '' && env_file == '' {
		return error('Either $env_var_name or $env_file_name is required.')
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

// load attempts to create the given type from environment variables.
pub fn load<T>() ?T {
	res := T{}

	$for field in T.fields {
		res.$(field.name) = get_env_var(field.name) or {
			// We use the default instead, if it's present
			mut default := ''

			for attr in field.attrs {
				if attr.starts_with('default: ') {
					default = attr[9..]
					break
				}
			}

			if default == '' {
				return err
			}

			default
		}
	}
	return res
}
