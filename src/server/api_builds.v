module server

/* import web */
/* import web.response { new_data_response, new_response } */
/* import time */
/* import build { BuildConfig } */
/* // import os */
/* // import util */
/* // import models { BuildLog, BuildLogFilter } */

/* ['/api/v1/builds/poll'; auth; get] */
/* fn (mut app App) v1_poll_build_queue() web.Result { */
/* 	arch := app.query['arch'] or { */
/* 		return app.json(.bad_request, new_response('Missing arch query arg.')) */
/* 	} */

/* 	max_str := app.query['max'] or { */
/* 		return app.json(.bad_request, new_response('Missing max query arg.')) */
/* 	} */
/* 	max := max_str.int() */

/* 	mut out := []BuildConfig{} */

/* 	now := time.now() */

/* 	lock app.build_queues { */
/* 		mut queue := app.build_queues[arch] or { return app.json(.ok, new_data_response(out)) } */

/* 		for queue.len() > 0 && out.len < max { */
/* 			next := queue.peek() or { return app.status(.internal_server_error) } */

/* 			if next.timestamp < now { */
/* 				out << queue.pop() or { return app.status(.internal_server_error) }.config */
/* 			} */
/* 		} */
/* 	} */

/* 	return app.json(.ok, new_data_response(out)) */
/* } */
