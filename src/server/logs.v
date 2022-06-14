module server

import web
import net.http
import net.urllib
import response { new_data_response, new_response }
import db
import time
import os
import util
import models { BuildLog, BuildLogFilter }

// v1_get_logs returns all build logs in the database. A 'repo' query param can
// optionally be added to limit the list of build logs to that repository.
['/api/v1/logs'; get]
fn (mut app App) v1_get_logs() web.Result {
	if !app.is_authorized() {
		return app.json(http.Status.unauthorized, new_response('Unauthorized.'))
	}

	filter := models.from_params<BuildLogFilter>(app.query) or {
		return app.json(http.Status.bad_request, new_response('Invalid query parameters.'))
	}
	logs := app.db.get_build_logs(filter)

	return app.json(http.Status.ok, new_data_response(logs))
}

// v1_get_single_log returns the build log with the given id.
['/api/v1/logs/:id'; get]
fn (mut app App) v1_get_single_log(id int) web.Result {
	if !app.is_authorized() {
		return app.json(http.Status.unauthorized, new_response('Unauthorized.'))
	}

	log := app.db.get_build_log(id) or { return app.not_found() }

	return app.json(http.Status.ok, new_data_response(log))
}

// v1_get_log_content returns the actual build log file for the given id.
['/api/v1/logs/:id/content'; get]
fn (mut app App) v1_get_log_content(id int) web.Result {
	if !app.is_authorized() {
		return app.json(http.Status.unauthorized, new_response('Unauthorized.'))
	}

	log := app.db.get_build_log(id) or { return app.not_found() }
	file_name := log.start_time.custom_format('YYYY-MM-DD_HH-mm-ss')
	full_path := os.join_path(app.conf.data_dir, logs_dir_name, log.repo_id.str(), log.arch,
		file_name)

	return app.file(full_path)
}

// parse_query_time unescapes an HTTP query parameter & tries to parse it as a
// time.Time struct.
fn parse_query_time(query string) ?time.Time {
	unescaped := urllib.query_unescape(query)?
	t := time.parse(unescaped)?

	return t
}

// v1_post_log adds a new log to the database.
['/api/v1/logs'; post]
fn (mut app App) v1_post_log() web.Result {
	if !app.is_authorized() {
		return app.json(http.Status.unauthorized, new_response('Unauthorized.'))
	}

	// Parse query params
	start_time_int := app.query['startTime'].int()

	if start_time_int == 0 {
		return app.json(http.Status.bad_request, new_response('Invalid or missing start time.'))
	}
	start_time := time.unix(start_time_int)

	end_time_int := app.query['endTime'].int()

	if end_time_int == 0 {
		return app.json(http.Status.bad_request, new_response('Invalid or missing end time.'))
	}
	end_time := time.unix(end_time_int)

	if 'exitCode' !in app.query {
		return app.json(http.Status.bad_request, new_response('Missing exit code.'))
	}

	exit_code := app.query['exitCode'].int()

	if 'arch' !in app.query {
		return app.json(http.Status.bad_request, new_response("Missing parameter 'arch'."))
	}

	arch := app.query['arch']

	repo_id := app.query['repo'].int()

	if !app.db.git_repo_exists(repo_id) {
		return app.json(http.Status.bad_request, new_response('Unknown Git repo.'))
	}

	// Store log in db
	log := BuildLog{
		repo_id: repo_id
		start_time: start_time
		end_time: end_time
		arch: arch
		exit_code: exit_code
	}

	app.db.add_build_log(log)

	repo_logs_dir := os.join_path(app.conf.data_dir, logs_dir_name, repo_id.str(), arch)

	// Create the logs directory of it doesn't exist
	if !os.exists(repo_logs_dir) {
		os.mkdir_all(repo_logs_dir) or {
			app.lerror("Couldn't create dir '$repo_logs_dir'.")

			return app.json(http.Status.internal_server_error, new_response('An error occured while processing the request.'))
		}
	}

	// Stream log contents to correct file
	file_name := start_time.custom_format('YYYY-MM-DD_HH-mm-ss')
	full_path := os.join_path_single(repo_logs_dir, file_name)

	if length := app.req.header.get(.content_length) {
		util.reader_to_file(mut app.reader, length.int(), full_path) or {
			app.lerror('An error occured while receiving logs: $err.msg()')

			return app.json(http.Status.internal_server_error, new_response('Failed to upload logs.'))
		}
	} else {
		return app.status(http.Status.length_required)
	}

	return app.json(http.Status.ok, new_response('Logs added successfully.'))
}
