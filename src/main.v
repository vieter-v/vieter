module main

import web
import os
import log
import io
import repo

const port = 8000

const buf_size = 1_000_000

const db_name = 'pieter.db'

struct App {
	web.Context
pub:
	api_key string [required; web_global]
pub mut:
	repo repo.Repo [required; web_global]
}

[noreturn]
fn exit_with_message(code int, msg string) {
	eprintln(msg)
	exit(code)
}

fn reader_to_file(mut reader io.BufferedReader, length int, path string) ? {
	// Open up a file for writing to
	mut file := os.create(path) ?
	defer {
		file.close()
	}

	mut buf := []byte{len: buf_size}
	mut bytes_left := length

	// Repeat as long as the stream still has data
	for bytes_left > 0 {
		// TODO check if just breaking here is safe
		bytes_read := reader.read(mut buf) or { break }
		bytes_left -= bytes_read

		mut to_write := bytes_read

		for to_write > 0 {
			// TODO don't just loop infinitely here
			bytes_written := file.write(buf[bytes_read - to_write..bytes_read]) or { continue }

			to_write = to_write - bytes_written
		}
	}
}

// fn main2() {
// 	// Configure logger
// 	log_level_str := os.getenv_opt('LOG_LEVEL') or { 'WARN' }
// 	log_level := log.level_from_tag(log_level_str) or {
// 		exit_with_message(1, 'Invalid log level. The allowed values are FATAL, ERROR, WARN, INFO & DEBUG.')
// 	}
// 	log_file := os.getenv_opt('LOG_FILE') or { 'vieter.log' }

// 	mut logger := log.Log{
// 		level: log_level
// 	}

// 	logger.set_full_logpath(log_file)
// 	logger.log_to_console_too()

// 	defer {
// 		logger.info('Flushing log file')
// 		logger.flush()
// 		logger.close()
// 	}

// 	// Configure web server
// 	key := os.getenv_opt('API_KEY') or { exit_with_message(1, 'No API key was provided.') }
// 	repo_dir := os.getenv_opt('REPO_DIR') or {
// 		exit_with_message(1, 'No repo directory was configured.')
// 	}

// 	repo := repo.Repo{
// 		dir: repo_dir
// 		name: db_name
// 	}

// 	// We create the upload directory during startup
// 	if !os.is_dir(repo.pkg_dir()) {
// 		os.mkdir_all(repo.pkg_dir()) or {
// 			exit_with_message(2, "Failed to create repo directory '$repo.pkg_dir()'.")
// 		}

// 		logger.info("Created package directory '$repo.pkg_dir()'.")
// 	}

// 	web.run(&App{
// 		logger: logger
// 		api_key: key
// 		repo: repo
// 	}, port)
// }

fn main() {
	r := repo.new('data/repo', 'data/pkgs') or { return }
	print(r.add_from_path('test/homebank-5.5.1-1-x86_64.pkg.tar.zst') or { panic('you fialed') })

	// archive.list_filenames()
	// res := pkg.read_pkg('test/jjr-joplin-desktop-2.6.10-4-x86_64.pkg.tar.zst') or {
	// 	eprintln(err.msg)
	// 	return
	// }
	// println(info)
	// println('hey')
	// print(res.to_desc())
	// print(res.to_files())
}
