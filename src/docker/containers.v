module docker

import json
import net.urllib
import time
import net.http { Method }

struct DockerError {
	message string
}

struct Container {
	id    string   [json: Id]
	names []string [json: Names]
}

// containers returns a list of all containers.
pub fn (mut d DockerConn) containers() ?[]Container {
	d.send_request(Method.get, urllib.parse('/v1.41/containers/json')?)?
	head, res := d.read_response()?

	if head.status_code != 200 {
		data := json.decode(DockerError, res)?

		return error(data.message)
	}

	data := json.decode([]Container, res)?

	return data
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
pub:
	id       string   [json: Id]
	warnings []string [json: Warnings]
}

// create_container creates a new container with the given config.
pub fn (mut d DockerConn) create_container(c NewContainer) ?CreatedContainer {
	d.send_request_with_json(Method.post, urllib.parse('/v1.41/containers/create')?, c)?
	head, res := d.read_response()?

	if head.status_code != 201 {
		data := json.decode(DockerError, res)?

		return error(data.message)
	}

	data := json.decode(CreatedContainer, res)?

	return data
}

// start_container starts the container with the given id.
pub fn (mut d DockerConn) start_container(id string) ? {
	d.send_request(Method.post, urllib.parse('/v1.41/containers/$id/start')?)?
	head, body := d.read_response()?

	if head.status_code != 204 {
		data := json.decode(DockerError, body)?

		return error(data.message)
	}
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

// inspect_container returns detailed information for a given container.
pub fn (mut d DockerConn) inspect_container(id string) ?ContainerInspect {
	d.send_request(Method.get, urllib.parse('/v1.41/containers/$id/json')?)?
	head, body := d.read_response()?

	if head.status_code != 200 {
		data := json.decode(DockerError, body)?

		return error(data.message)
	}

	mut data := json.decode(ContainerInspect, body)?

	data.state.start_time = time.parse_rfc3339(data.state.start_time_str)?

	if data.state.status == 'exited' {
		data.state.end_time = time.parse_rfc3339(data.state.end_time_str)?
	}

	return data
}

// remove_container removes the container with the given id.
pub fn (mut d DockerConn) remove_container(id string) ? {
	d.send_request(Method.delete, urllib.parse('/v1.41/containers/$id')?)?
	head, body := d.read_response()?

	if head.status_code != 204 {
		data := json.decode(DockerError, body)?

		return error(data.message)
	}
}

// get_container_logs returns a reader object allowing access to the
// container's logs.
pub fn (mut d DockerConn) get_container_logs(id string) ?&StreamFormatReader {
	d.send_request(Method.get, urllib.parse('/v1.41/containers/$id/logs?stdout=true&stderr=true')?)?
	head := d.read_response_head()?

	if head.status_code != 200 {
		content_length := head.header.get(http.CommonHeader.content_length)?.int()
		body := d.read_response_body(content_length)?
		data := json.decode(DockerError, body)?

		return error(data.message)
	}

	return d.get_stream_format_reader()
}
