module models

import time

// from_params<T> creates a new instance of T from the given map by parsing all
// of its fields from the map.
pub fn from_params<T>(params map[string]string) ?T {
	mut o := T{}

	patch_from_params<T>(mut o, params)?

	return o
}

// patch_from_params<T> updates the given T object with the params defined in
// the map.
pub fn patch_from_params<T>(mut o T, params map[string]string) ? {
	$for field in T.fields {
		if field.name in params && params[field.name] != '' {
			$if field.typ is string {
				o.$(field.name) = params[field.name]
			} $else $if field.typ is int {
				o.$(field.name) = params[field.name].int()
			} $else $if field.typ is u64 {
				o.$(field.name) = params[field.name].u64()
			} $else $if field.typ is []GitRepoArch {
				o.$(field.name) = params[field.name].split(',').map(GitRepoArch{ value: it })
			} $else $if field.typ is time.Time {
				o.$(field.name) = time.unix(params[field.name].int())
			} $else $if field.typ is []string {
				o.$(field.name) = params[field.name].split(',')
			}
		} else if field.attrs.contains('nonull') {
			return error('Missing parameter: ${field.name}.')
		}
	}
}

// params_from<T> converts a given T struct into a map of strings.
pub fn params_from<T>(o &T) map[string]string {
	mut out := map[string]string{}

	$for field in T.fields {
		$if field.typ is time.Time {
			out[field.name] = o.$(field.name).unix_time().str()
		} $else $if field.typ is []string {
			out[field.name] = o.$(field.name).join(',')
		} $else {
			out[field.name] = o.$(field.name).str()
		}
	}
	return out
}
