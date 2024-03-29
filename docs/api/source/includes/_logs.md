# Build Logs

<aside class="notice">

All routes in this section require authentication.

</aside>

Endpoints for interacting with stored build logs.

## List logs

```shell
curl \
  -H 'X-Api-Key: secret' \
  https://example.com/api/v1/logs?offset=10&limit=20
```

> JSON output format

```json
{
  "message": "",
  "data": [
    {
      "id": 1,
      "target_id": 3,
      "start_time": 1652008554,
      "end_time": 1652008559,
      "arch": "x86_64",
      "exit_code": 0
    }
  ]
}
```

Retrieve a list of build logs.

### HTTP Request

`GET /api/v1/logs`

### Query Parameters

Parameter | Description
--------- | -----------
limit | Maximum amount of results to return.
offset | Offset of results.
target | Only return builds for this target id.
before | Only return logs started before this time (UTC epoch)
after | Only return logs started after this time (UTC epoch)
arch | Only return logs built on this architecture
exit_codes | Comma-separated list of exit codes to limit result to; using `!` as a prefix makes it exclude that value. For example, `1,2` only returns logs with status code 1 or 2, while `!1,!2` returns those that don't have 1 or 2 as the result.


## Get build log

```shell
curl \
  -H 'X-Api-Key: secret' \
  https://example.com/api/v1/logs/1
```

> JSON output format

```json
{
  "message": "",
  "data": {
    "id": 1,
    "target_id": 3,
    "start_time": 1652008554,
    "end_time": 1652008559,
    "arch": "x86_64",
    "exit_code": 0
  }
}
```

Retrieve info about a specific build log.

### HTTP Request

`GET /api/v1/logs/:id`

### URL Parameters

Parameter | Description
--------- | -----------
id | ID of requested log

## Get log contents

```shell
curl \
  -H 'X-Api-Key: secret' \
  https://example.com/api/v1/logs/15/content
```

Retrieve the contents of a build log. The response is the build log in
plaintext.

### HTTP Request

`GET /api/v1/logs/:id/content`

### URL Parameters

Parameter | Description
--------- | -----------
id | ID of requested log

## Publish build log

> JSON output format

```json
{
  "message": "",
  "data": {
    "id": 15
  }
}
```

<aside class="warning">

This endpoint is used by the agents and should not be used manually unless you
know what you're doing. It's just here for completeness.

</aside>

Publish a new build log to the server.

### HTTP Request

`POST /api/v1/logs`

### Query parameters

Parameter | Description
--------- | -----------
startTime | Start time of the build (UTC epoch)
endTime | End time of the build (UTC epoch)
arch | Architecture on which the build was done
exitCode | Exit code of the build container
target | id of target this build is for

### Request body

Plaintext contents of the build log.

## Remove a build log

```shell
curl \
  -XDELETE \
  -H 'X-Api-Key: secret' \
  https://example.com/api/v1/logs/1
```

Remove a build log from the server.

### HTTP Request

`DELETE /api/v1/logs/:id`

### URL Parameters

Parameter | Description
--------- | -----------
id | id of log to remove
