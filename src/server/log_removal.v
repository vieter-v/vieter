module server

import time
import models { BuildLog }
import os
import cron

const fallback_log_removal_frequency = 24 * time.hour

// log_removal_daemon removes old build logs every `log_removal_frequency`.
fn (mut app App) log_removal_daemon(schedule &cron.Expression) {
	for {
		mut too_old_timestamp := time.now().add_days(-app.conf.max_log_age)

		app.linfo('Cleaning logs before $too_old_timestamp')

		mut logs := []BuildLog{}
		mut counter := 0
		mut failed := u64(0)

		// Remove old logs
		for {
			// The offset is used to skip logs that failed to remove. Besides
			// this, we don't need to move the offset, because all previously
			// oldest logs will have been removed.
			logs = app.db.get_build_logs(before: too_old_timestamp, offset: failed, limit: 50)

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
		}

		app.linfo('Cleaned $counter logs ($failed failed)')

		// Sleep until the next cycle
		next_time := schedule.next_from_now()
		time.sleep(next_time - time.now())
	}
}
