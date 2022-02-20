module docker

import json
import net.urllib

struct Container {
	id    string   [json: Id]
	names []string [json: Names]
}

pub fn containers() ?[]Container {
	res := get(urllib.parse('/containers/json') ?) ?

	return json.decode([]Container, res.text) or {}
}
