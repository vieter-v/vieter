module fibonacci

pub fn fib(i int) int {
	if i <= 1 {
		return i
	}

	return fib(i - 1) + fib(i - 2)
}
