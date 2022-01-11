module main

import net.http

fn (mut app App) is_authorized() bool {
	x_header := app.req.header.get_custom('X-Api-Key', http.HeaderQueryConfig{ exact: true }) or {
		return false
	}

	return x_header.trim_space() == app.api_key
}
