module server

import web
import net.urllib
import web.response { new_data_response, new_response }
import time
import os
import util
import models { BuildLog, BuildLogFilter }

// v1_get_logs returns all build logs in the database. A 'target' query param can
// optionally be added to limit the list of build logs to that repository.
['/api/v1/logs'; auth; get; markused]
fn (mut app App) v1_get_logs() web.Result {
	filter := models.from_params[BuildLogFilter](app.query) or {
		return app.json(.bad_request, new_response('Invalid query parameters.'))
	}
	logs := app.db.get_build_logs(filter)

	return app.json(.ok, new_data_response(logs))
}

// v1_get_single_log returns the build log with the given id.
['/api/v1/logs/:id'; auth; get; markused]
fn (mut app App) v1_get_single_log(id int) web.Result {
	log := app.db.get_build_log(id) or { return app.status(.not_found) }

	return app.json(.ok, new_data_response(log))
}

// v1_get_log_content returns the actual build log file for the given id.
['/api/v1/logs/:id/content'; auth; get; markused]
fn (mut app App) v1_get_log_content(id int) web.Result {
	log := app.db.get_build_log(id) or { return app.status(.not_found) }
	file_name := log.start_time.custom_format('YYYY-MM-DD_HH-mm-ss')
	full_path := os.join_path(app.conf.data_dir, logs_dir_name, log.target_id.str(), log.arch,
		file_name)

	return app.file(full_path)
}

// parse_query_time unescapes an HTTP query parameter & tries to parse it as a
// time.Time struct.
fn parse_query_time(query string) !time.Time {
	unescaped := urllib.query_unescape(query)!
	t := time.parse(unescaped)!

	return t
}

// v1_post_log adds a new log to the database.
['/api/v1/logs'; auth; markused; post]
fn (mut app App) v1_post_log() web.Result {
	// Parse query params
	start_time_int := app.query['startTime'].int()

	if start_time_int == 0 {
		return app.json(.bad_request, new_response('Invalid or missing start time.'))
	}
	start_time := time.unix(start_time_int)

	end_time_int := app.query['endTime'].int()

	if end_time_int == 0 {
		return app.json(.bad_request, new_response('Invalid or missing end time.'))
	}
	end_time := time.unix(end_time_int)

	if 'exitCode' !in app.query {
		return app.json(.bad_request, new_response('Missing exit code.'))
	}

	exit_code := app.query['exitCode'].int()

	if 'arch' !in app.query {
		return app.json(.bad_request, new_response("Missing parameter 'arch'."))
	}

	arch := app.query['arch']

	target_id := app.query['target'].int()

	if !app.db.target_exists(target_id) {
		return app.json(.bad_request, new_response('Unknown target.'))
	}

	// Store log in db
	mut log := BuildLog{
		target_id: target_id
		start_time: start_time
		end_time: end_time
		arch: arch
		exit_code: exit_code
	}

	// id of newly created log
	log.id = app.db.add_build_log(log)
	log_file_path := os.join_path(app.conf.data_dir, logs_dir_name, log.path())

	// Create the logs directory of it doesn't exist
	if !os.exists(os.dir(log_file_path)) {
		os.mkdir_all(os.dir(log_file_path)) or {
			app.lerror('Error while creating log file: ${err.msg()}')

			return app.status(.internal_server_error)
		}
	}

	if length := app.req.header.get(.content_length) {
		util.reader_to_file(mut app.reader, length.int(), log_file_path) or {
			app.lerror('An error occured while receiving logs: ${err.msg()}')

			return app.status(.internal_server_error)
		}
	} else {
		return app.status(.length_required)
	}

	return app.json(.ok, new_data_response(log.id))
}

// v1_delete_log allows removing a build log from the system.
['/api/v1/logs/:id'; auth; delete; markused]
fn (mut app App) v1_delete_log(id int) web.Result {
	log := app.db.get_build_log(id) or { return app.status(.not_found) }
	full_path := os.join_path(app.conf.data_dir, logs_dir_name, log.path())

	os.rm(full_path) or {
		app.lerror('Failed to remove log file ${full_path}: ${err.msg()}')

		return app.status(.internal_server_error)
	}

	app.db.delete_build_log(id)

	return app.status(.ok)
}
