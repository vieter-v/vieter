# Jobs

<aside class="notice">

All routes in this section require authentication.

</aside>

## Manually schedule a job

```shell
curl \
  -H 'X-Api-Key: secret' \
  https://example.com/api/v1/jobs/queue?target=10&force&arch=x86_64
```

Manually schedule a job on the server.

### HTTP Request

`POST /api/v1/jobs/queue`

### Query Parameters

Parameter | Description
--------- | -----------
target | Id of target to schedule build for
arch | Architecture to build on
force | Whether it's a forced build (true if present)

## Poll for new jobs

<aside class="warning">

This endpoint is used by the agents and should not be used manually. It's just
here for completeness.

</aside>

Poll the server for new builds.

### HTTP Request

`GET /api/v1/jobs/poll`

### Query Parameters

Parameter | Description
--------- | -----------
arch | For which architecture to receive jobs
max | How many jobs to receive at most
