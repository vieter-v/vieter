module models

pub fn from_params<T>(params map[string]string) ?T {
	mut o := T{}

	patch_from_params<T>(mut o, params)?

	return o
}

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
			}
		} else if field.attrs.contains('nonull') {
			return error('Missing parameter: ${field.name}.')
		}
	}
}

pub fn params_from<T>(o &T) map[string]string {
	mut out := map[string]string{}

	$for field in T.fields {
		out[field.name] = o.$(field.name).str()
	}
	return out
}
