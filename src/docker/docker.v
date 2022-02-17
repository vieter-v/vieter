module docker

import net.unix
import net.urllib
import net.http

const socket = '/var/run/docker.sock'
const buf_len = 1024

fn request(method string, url urllib.URL) ?http.Response {
    req := "$method $url.request_uri() HTTP/1.1\nHost: localhost\n\n"

    // Open a connection to the socket
    mut s := unix.connect_stream(socket) ?

    defer {
        s.close() ?
    }

    // Write the request to the socket
    s.write_string(req) ?

    // Wait for the server to respond
    s.wait_for_write() ?

    mut buf := []byte{len: buf_len}
    mut res := []byte{}

    mut c := 0

    for {
        c = s.read(mut buf) or {
            return error('Failed to read data from socket.')
        }
        res << buf[..c]

        if c < buf_len {
            break
        }
    }

    // Decode chunked response
    return http.parse_response(res.bytestr())
}

fn get(url urllib.URL) ?http.Response {
    return request('GET', url)
}
