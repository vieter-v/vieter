module docker

import json
import net.urllib

struct Container {
	id    string   [json: Id]
	names []string [json: Names]
}

// containers returns a list of all currently running containers
pub fn containers() ?[]Container {
	res := request('GET', urllib.parse('/containers/json') ?) ?

	return json.decode([]Container, res.text) or {}
}

pub struct NewContainer {
	image      string   [json: Image]
	entrypoint []string [json: Entrypoint]
	cmd        []string [json: Cmd]
	env        []string [json: Env]
}

struct CreatedContainer {
	id string [json: Id]
}

// create_container creates a container defined by the given configuration. If
// successful, it returns the ID of the newly created container.
pub fn create_container(c &NewContainer) ?string {
	res := request_with_json('POST', urllib.parse('/containers/create') ?, c) ?

	if res.status_code != 201 {
		return error('Failed to create container.')
	}

	return json.decode(CreatedContainer, res.text) ?.id
}

// start_container starts a container with a given ID. It returns whether the
// container was started or not.
pub fn start_container(id string) ?bool {
	res := request('POST', urllib.parse('/containers/$id/start') ?) ?

	return res.status_code == 204
}

struct ContainerInspect {
pub:
	state ContainerState [json: State]
}

struct ContainerState {
pub:
	running bool [json: Running]
}

// inspect_container returns the result of inspecting a container with a given
// ID.
pub fn inspect_container(id string) ?ContainerInspect {
	res := request('GET', urllib.parse('/containers/$id/json') ?) ?

	if res.status_code != 200 {
		return error('Failed to inspect container.')
	}

	return json.decode(ContainerInspect, res.text) or {}
}

// remove_container removes a container with a given ID.
pub fn remove_container(id string) ?bool {
	res := request('DELETE', urllib.parse('/containers/$id') ?) ?

	return res.status_code == 204
}
