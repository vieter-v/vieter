module response

pub struct Response<T> {
pub:
	message string
	data    T
}

// new_response constructs a new Response<String> object with the given message
// & an empty data field.
pub fn new_response(message string) Response<string> {
	return Response<string>{
		message: message
		data: ''
	}
}

// new_data_response<T> constructs a new Response<T> object with the given data
// & an empty message field.
pub fn new_data_response<T>(data T) Response<T> {
	return Response<T>{
		message: ''
		data: data
	}
}

// new_full_response<T> constructs a new Response<T> object with the given
// message & data.
pub fn new_full_response<T>(message string, data T) Response<T> {
	return Response<T>{
		message: message
		data: data
	}
}
