module server

import net.http

// is_authorized checks whether the provided API key is correct.
fn (mut app App) is_authorized() bool {
	x_header := app.req.header.get_custom('X-Api-Key', http.HeaderQueryConfig{ exact: true }) or {
		return false
	}

	return x_header.trim_space() == app.conf.api_key
}
