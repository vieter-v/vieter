module server

import time
import models { BuildLog }
import os
import cron.expression { CronExpression }

const fallback_log_removal_frequency = 24 * time.hour

// log_removal_daemon removes old build logs every `log_removal_frequency`.
fn (mut app App) log_removal_daemon(schedule CronExpression) {
	mut start_time := time.Time{}

	for {
		start_time = time.now()

		mut too_old_timestamp := time.now().add_days(-app.conf.max_log_age)

		app.linfo('Cleaning logs before $too_old_timestamp')

		mut offset := u64(0)
		mut logs := []BuildLog{}
		mut counter := 0
		mut failed := 0

		// Remove old logs
		for {
			logs = app.db.get_build_logs(before: too_old_timestamp, offset: offset, limit: 50)

			for log in logs {
				log_file_path := os.join_path(app.conf.data_dir, logs_dir_name, log.path())

				os.rm(log_file_path) or {
					app.lerror('Failed to remove log file $log_file_path: $err.msg()')
					failed += 1

					continue
				}
				app.db.delete_build_log(log.id)

				counter += 1
			}

			if logs.len < 50 {
				break
			}

			offset += 50
		}

		app.linfo('Cleaned $counter logs ($failed failed)')

		// Sleep until the next cycle
		next_time := schedule.next_from_now() or {
			app.lerror("Log removal daemon couldn't calculate next time: $err.msg(); fallback to $server.fallback_log_removal_frequency")

			start_time.add(server.fallback_log_removal_frequency)
		}

		time.sleep(next_time - time.now())
	}
}
