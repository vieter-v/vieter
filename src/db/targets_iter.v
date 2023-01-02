module db

import models { Target, TargetFilter }
import sqlite

// Iterator providing a filtered view into the list of targets currently stored
// in the database. It replaces functionality usually performed in the database
// using SQL queries that can't currently be used due to missing stuff in V's
// ORM.
pub struct TargetsIterator {
	conn        sqlite.DB
	filter      TargetFilter
	window_size int = 32
mut:
	window       []Target
	window_index u64
	// Offset in entire list of unfiltered targets
	offset int
	// Offset in filtered list of targets
	filtered_offset u64
	started         bool
	done            bool
}

// targets returns an iterator allowing filtered access to the list of targets.
pub fn (db &VieterDb) targets(filter TargetFilter) TargetsIterator {
	window_size := 32

	return TargetsIterator{
		conn: db.conn
		filter: filter
		window: []Target{cap: window_size}
		window_size: window_size
	}
}

// advance_window moves the sliding window over the filtered list of targets
// until it either reaches the end of the list of targets, or has encountered a
// non-empty window.
fn (mut ti TargetsIterator) advance_window() {
	for {
		ti.window = sql ti.conn {
			select from Target order by id limit ti.window_size offset ti.offset
		}
		ti.offset += ti.window.len

		if ti.window.len == 0 {
			ti.done = true

			return
		}

		if ti.filter.repo != '' {
			ti.window = ti.window.filter(it.repo == ti.filter.repo)
		}

		if ti.filter.arch != '' {
			ti.window = ti.window.filter(it.arch.any(it.value == ti.filter.arch))
		}

		if ti.filter.query != '' {
			ti.window = ti.window.filter(it.url.contains(ti.filter.query)
				|| it.path.contains(ti.filter.query) || it.branch.contains(ti.filter.query))
		}

		if ti.window.len > 0 {
			break
		}
	}
}

// next returns the next target, if possible.
pub fn (mut ti TargetsIterator) next() ?Target {
	if ti.done {
		return none
	}

	// The first call to `next` will cause the sliding window to move to where the requested offset starts
	if !ti.started {
		ti.advance_window()

		// Skip all matched targets until the requested offset
		for !ti.done && ti.filtered_offset + u64(ti.window.len) <= ti.filter.offset {
			ti.filtered_offset += u64(ti.window.len)
			ti.advance_window()
		}

		if ti.done {
			return none
		}

		left_inside_window := ti.filter.offset - ti.filtered_offset
		ti.window_index = left_inside_window
		ti.filtered_offset += left_inside_window

		ti.started = true
	}

	return_value := ti.window[ti.window_index]

	ti.window_index++
	ti.filtered_offset++

	// Next call will be past the requested offset
	if ti.filter.limit > 0 && ti.filtered_offset == ti.filter.offset + ti.filter.limit {
		ti.done = true
	}

	// Ensure the next call has a new valid window
	if ti.window_index == u64(ti.window.len) {
		ti.advance_window()
		ti.window_index = 0
	}

	return return_value
}

// collect consumes the entire iterator & returns the result as an array.
pub fn (mut ti TargetsIterator) collect() []Target {
	mut out := []Target{}

	for t in ti {
		out << t
	}

	return out
}
