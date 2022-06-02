module console

import arrays
import strings
import cli
import os

// pretty_table converts a list of string data into a pretty table. Many thanks
// to @hungrybluedev in the Vlang Discord for providing this code!
// https://ptb.discord.com/channels/592103645835821068/592106336838352923/970278787143045192
pub fn pretty_table(header []string, data [][]string) ?string {
	column_count := header.len

	mut column_widths := []int{len: column_count, init: header[it].len}

	for values in data {
		for col, value in values {
			if column_widths[col] < value.len {
				column_widths[col] = value.len
			}
		}
	}

	single_line_length := arrays.sum(column_widths)? + (column_count + 1) * 3 - 4

	horizontal_line := '+' + strings.repeat(`-`, single_line_length) + '+'
	mut buffer := strings.new_builder(data.len * single_line_length)

	buffer.writeln(horizontal_line)

	buffer.write_string('| ')
	for col, head in header {
		if col != 0 {
			buffer.write_string(' | ')
		}
		buffer.write_string(head)
		buffer.write_string(strings.repeat(` `, column_widths[col] - head.len))
	}
	buffer.writeln(' |')

	buffer.writeln(horizontal_line)

	for values in data {
		buffer.write_string('| ')
		for col, value in values {
			if col != 0 {
				buffer.write_string(' | ')
			}
			buffer.write_string(value)
			buffer.write_string(strings.repeat(` `, column_widths[col] - value.len))
		}
		buffer.writeln(' |')
	}

	buffer.writeln(horizontal_line)

	return buffer.str()
}

// export_man_pages recursively generates all man pages for the given
// cli.Command & writes them to the given directory.
pub fn export_man_pages(cmd cli.Command, path string) ? {
	man := cmd.manpage()
	os.write_file(os.join_path_single(path, cmd.full_name().replace(' ', '-') + '.1'),
		man)?

	for sub_cmd in cmd.commands {
		export_man_pages(sub_cmd, path)?
	}
}
