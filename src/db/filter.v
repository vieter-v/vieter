module db

pub struct GitRepoFilter {
pub mut:
	limit  u64 = 25
	offset u64
	repo   string
}

pub fn filter_from_params<T>(params map[string]string) ?T {
	mut o := GitRepoFilter{}

	$for field in T.fields {
		if field.name in params {
			val := params[field.name]

			$if field.typ is string {
				o.$(field.name) = val
			} $else $if field.typ is u64 {
				o.$(field.name) = val.u64()
			}
		}
	}
	return o
}
