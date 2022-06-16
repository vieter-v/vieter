This module contains the Vieter HTTP server, consisting of the repository
implementation & the REST API.

**NOTE**: vweb defines the priority order of routes by the file names in this
module. Therefore, it's very important that all API routes are defined in files
prefixed with `api_`, as this is before the word `routes` alphabetically.
