module client

import models { Target, TargetFilter }

// get_targets returns a list of targets, given a filter object.
pub fn (c &Client) get_targets(filter TargetFilter) ![]Target {
	params := models.params_from(filter)
	data := c.send_request[[]Target](.get, '/api/v1/targets', params)!

	return data.data
}

// get_all_targets retrieves *all* targs from the API using the default
// limit.
pub fn (c &Client) get_all_targets() ![]Target {
	mut targets := []Target{}
	mut offset := u64(0)

	for {
		sub_targets := c.get_targets(offset: offset)!

		if sub_targets.len == 0 {
			break
		}

		targets << sub_targets

		offset += u64(sub_targets.len)
	}

	return targets
}

// get_target returns the target for a specific id.
pub fn (c &Client) get_target(id int) !Target {
	data := c.send_request[Target](.get, '/api/v1/targets/${id}', {})!

	return data.data
}

pub struct NewTarget {
	kind   string
	url    string
	branch string
	repo   string
	path   string
	arch   []string
}

// add_target adds a new target to the server.
pub fn (c &Client) add_target(t NewTarget) !int {
	params := models.params_from[NewTarget](t)
	data := c.send_request[int](.post, '/api/v1/targets', params)!

	return data.data
}

// remove_target removes the target with the given id from the server.
pub fn (c &Client) remove_target(id int) !string {
	data := c.send_request[string](.delete, '/api/v1/targets/${id}', {})!

	return data.data
}

// patch_target sends a PATCH request to the given target with the params as
// payload.
pub fn (c &Client) patch_target(id int, params map[string]string) !string {
	data := c.send_request[string](.patch, '/api/v1/targets/${id}', params)!

	return data.data
}
