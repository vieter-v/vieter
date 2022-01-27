#!/usr/bin/env sh
# This file patches the downloaded V version
# Should be run from within the directory it's in, as it uses relative paths to the files used for patching.
# $1 is the path to the downloaded V version

# Add parse_request_no_body
cat parse_request_no_body.v >> "$1"/vlib/net/http/request.v
