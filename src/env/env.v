module env

import os
import toml

const (
	// The prefix that every environment variable should have
	prefix      = 'VIETER_'
	// The suffix an environment variable in order for it to be loaded from a file
	// instead
	file_suffix = '_FILE'
)

// get_env_var tries to read the contents of the given environment variable. It
// looks for either `${env.prefix}${field_name.to_upper()}` or
// `${env.prefix}${field_name.to_upper()}${env.file_suffix}`, returning the
// contents of the file instead if the latter. If both or neither exist, the
// function returns an error.
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
		error('Failed to read file defined in $env_file_name: ${err.msg()}.')
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
		doc := toml.parse_file(path)?

		$for field in T.fields {
			s := doc.value(field.name)

			if s !is toml.Null {
				$if field.typ is string {
					res.$(field.name) = s.string()
				} $else $if field.typ is int {
					res.$(field.name) = s.int()
				}
			}
		}
	}

	$for field in T.fields {
		env_value := get_env_var(field.name)?

		// The value of an env var will always take precedence over the toml
		// file.
		if env_value != '' {
			$if field.typ is string {
				res.$(field.name) = env_value
			} $else $if field.typ is int {
				res.$(field.name) = env_value.int()
			}
		}

		// Now, we check whether a value is present. If there isn't, that means
		// it isn't in the config file, nor is there a default or an env var.
		mut has_value := false

		$if field.typ is string {
			has_value = res.$(field.name) != ''
		} $else $if field.typ is int {
			has_value = res.$(field.name) != 0
		}

		if !has_value {
			return error("Missing config variable '$field.name' with no provided default. Either add it to the config file or provide it using an environment variable.")
		}
	}
	return res
}
