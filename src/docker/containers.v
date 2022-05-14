module docker

import json
import net.urllib
import time

struct Container {
	id    string   [json: Id]
	names []string [json: Names]
}

// containers returns a list of all currently running containers
pub fn containers() ?[]Container {
	res := request('GET', urllib.parse('/v1.41/containers/json')?)?

	return json.decode([]Container, res.text) or {}
}

pub struct NewContainer {
	image      string   [json: Image]
	entrypoint []string [json: Entrypoint]
	cmd        []string [json: Cmd]
	env        []string [json: Env]
	work_dir   string   [json: WorkingDir]
	user       string   [json: User]
}

struct CreatedContainer {
	id string [json: Id]
}

// create_container creates a container defined by the given configuration. If
// successful, it returns the ID of the newly created container.
pub fn create_container(c &NewContainer) ?string {
	res := request_with_json('POST', urllib.parse('/v1.41/containers/create')?, c)?

	if res.status_code != 201 {
		return error('Failed to create container.')
	}

	return json.decode(CreatedContainer, res.text)?.id
}

// start_container starts a container with a given ID. It returns whether the
// container was started or not.
pub fn start_container(id string) ?bool {
	res := request('POST', urllib.parse('/v1.41/containers/$id/start')?)?

	return res.status_code == 204
}

struct ContainerInspect {
pub mut:
	state ContainerState [json: State]
}

struct ContainerState {
pub:
	running   bool   [json: Running]
	status    string [json: Status]
	exit_code int    [json: ExitCode]
	// These use a rather specific format so they have to be parsed later
	start_time_str string [json: StartedAt]
	end_time_str   string [json: FinishedAt]
pub mut:
	start_time time.Time [skip]
	end_time   time.Time [skip]
}

// inspect_container returns the result of inspecting a container with a given
// ID.
pub fn inspect_container(id string) ?ContainerInspect {
	res := request('GET', urllib.parse('/v1.41/containers/$id/json')?)?

	if res.status_code != 200 {
		return error('Failed to inspect container.')
	}

	mut data := json.decode(ContainerInspect, res.text)?

	data.state.start_time = time.parse_rfc3339(data.state.start_time_str)?

	if data.state.status == 'exited' {
		data.state.end_time = time.parse_rfc3339(data.state.end_time_str)?
	}

	return data
}

// remove_container removes a container with a given ID.
pub fn remove_container(id string) ?bool {
	res := request('DELETE', urllib.parse('/v1.41/containers/$id')?)?

	return res.status_code == 204
}

// get_container_logs retrieves the logs for a Docker container, both stdout &
// stderr.
pub fn get_container_logs(id string) ?string {
	res := request('GET', urllib.parse('/v1.41/containers/$id/logs?stdout=true&stderr=true')?)?
	mut res_bytes := res.text.bytes()

	// Docker uses a special "stream" format for their logs, so we have to
	// clean up the data.
	mut index := 0

	for index < res_bytes.len {
		// The reverse is required because V reads in the bytes differently
		t := res_bytes[index + 4..index + 8].reverse()
		len_length := unsafe { *(&u32(&t[0])) }

		res_bytes.delete_many(index, 8)
		index += int(len_length)
	}

	return res_bytes.bytestr()
}
