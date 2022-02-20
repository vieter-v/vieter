module docker

import json
import net.urllib

struct Container {
	id    string   [json: Id]
	names []string [json: Names]
}

pub fn containers() ?[]Container {
	res := request('GET', urllib.parse('/containers/json') ?) ?

	return json.decode([]Container, res.text) or {}
}

pub struct NewContainer {
	image string [json: Image]
	entrypoint []string [json: Entrypoint]
	cmd []string [json: Cmd]
	env []string [json: Env]
}

struct CreatedContainer {
	id string [json: Id]
}

pub fn create_container(c &NewContainer) ?string {
	res := request_with_json('POST', urllib.parse('/containers/create') ?, c) ?

	if res.status_code != 201 {
		return error('Failed to create container.')
	}

	return json.decode(CreatedContainer, res.text) ?.id
}

pub fn start_container(id string) ?bool {
	res := request('POST', urllib.parse('/containers/$id/start') ?) ?
	println(res)

	return res.status_code == 204
}
