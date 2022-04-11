module env

import os
import toml

// The prefix that every environment variable should have
const prefix = 'VIETER_'

// The suffix an environment variable in order for it to be loaded from a file
// instead
const file_suffix = '_FILE'

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

// load<T> attempts to create an object of type T from the given path to a toml
// file & environment variables. For each field, it will select either a value
// given from an environment variable, a value defined in the config file or a
// configured default if present, in that order.
pub fn load<T>(path string) ?T {
	mut res := T{}

	if os.exists(path) {
		// We don't use reflect here because reflect also sets any fields not
		// in the toml back to their zero value, which we don't want
		doc := toml.parse_file(path) ?

		$for field in T.fields {
			s := doc.value(field.name)

			// We currently only support strings
			if s.type_name() == 'string' {
				res.$(field.name) = s.string()
			}
		}
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
				return error("Missing config variable '$field.name' with no provided default. Either add it to the config file or provide it using an environment variable.")
			}
		}
	}
	return res
}
