module main

import fibonacci

fn main() {
	println('Hello, world!')

	for i in 1 .. 35 {
		println('$i - ${fibonacci.fib(i)}')
	}
}
