module server

import web
import net.http
import net.urllib
import response { new_data_response, new_response }
import db
import time
import os
import util

['/api/logs'; get]
fn (mut app App) get_logs() web.Result {
	if !app.is_authorized() {
		return app.json(http.Status.unauthorized, new_response('Unauthorized.'))
	}

	logs := if 'repo' in app.query {
		app.db.get_build_logs_for_repo(app.query['repo'].int())
	} else {
		app.db.get_build_logs()
	}

	return app.json(http.Status.ok, new_data_response(logs))
}

// parse_query_time unescapes an HTTP query parameter & tries to parse it as a
// time.Time struct.
fn parse_query_time(query string) ?time.Time {
	unescaped := urllib.query_unescape(query) ?
	t := time.parse(unescaped) ?

	return t
}

['/api/logs'; post]
fn (mut app App) post_log() web.Result {
	if !app.is_authorized() {
		return app.json(http.Status.unauthorized, new_response('Unauthorized.'))
	}

	// Parse query params
	start_time := parse_query_time(app.query['startTime']) or {
		return app.json(http.Status.bad_request, new_response('Invalid or missing start time.'))
	}

	end_time := time.parse(app.query['endTime'].replace('_', ' ')) or {
		return app.json(http.Status.bad_request, new_response('Invalid or missing end time.'))
	}

	if 'exitCode' !in app.query {
		return app.json(http.Status.bad_request, new_response('Missing exit code.'))
	}

	exit_code := app.query['exitCode'].int()

	if 'arch' !in app.query {
		return app.json(http.Status.bad_request, new_response("Missing parameter 'arch'."))
	}

	arch := app.query['arch']

	repo := app.query['repo'].int()

	if repo == 0 {
		return app.json(http.Status.bad_request, new_response('Invalid Git repo.'))
	}

	// Store log in db
	log := db.BuildLog{
		repo_id: repo
		start_time: start_time
		end_time: end_time
		exit_code: exit_code
	}

	app.db.add_build_log(log)

	repo_logs_dir := os.join_path(app.conf.data_dir, logs_dir_name, repo.str(), arch)

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
