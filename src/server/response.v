module server

struct Response<T> {
	message string
	data T
}

fn new_response(message string) Response<string> {
	return Response<string>{
		message: message
		data: ""
	}
}

fn new_data_response<T>(data T) Response<T> {
	return Response<T>{
		message: ""
		data: data
	}
}

fn new_full_response<T>(message string, data T) Response<T> {
	return Response<T>{
		message: message
		data: data
	}
}
