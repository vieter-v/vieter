# Targets

<aside class="notice">

All routes in this section require authentication.

</aside>

Endpoints for interacting with the list of targets stored on the server.

## List targets

```shell
curl \
  -H 'X-Api-Key: secret' \
  https://example.com/api/v1/targets?offset=10&limit=20
```

> JSON output format

```json
{
  "message": "",
  "data": [
    {
      "id": 1,
      "kind": "git",
      "url": "https://aur.archlinux.org/discord-ptb.git",
      "branch": "master",
      "repo": "bur",
      "schedule": "",
      "arch": [
        {
          "id": 1,
          "target_id": 1,
          "value": "x86_64"
        }
      ]
    }
  ]
}
```

Retrieve a list of targets.

### HTTP Request

`GET /api/v1/targets`

### Query Parameters

Parameter | Description
--------- | -----------
limit | Maximum amount of results to return.
offset | Offset of results.
repo | Limit results to targets that publish to the given repo.

## Get specific target

```shell
curl \
  -H 'X-Api-Key: secret' \
  https://example.com/api/v1/targets/1
```

> JSON output format

```json
{
  "message": "",
  "data": {
    "id": 1,
    "kind": "git",
    "url": "https://aur.archlinux.org/discord-ptb.git",
    "branch": "master",
    "repo": "bur",
    "schedule": "0 3",
    "arch": [
      {
        "id": 1,
        "target_id": 1,
        "value": "x86_64"
      }
    ]
  }
}
```

Get info about a specific target.

### HTTP Request

`GET /api/v1/targets/:id`

### URL Parameters

Parameter | Description
--------- | -----------
id | id of requested target

## Create a new target

Create a new target with the given data.

### HTTP Request

`POST /api/v1/targets`

### Query Parameters

Parameter | Description
--------- | -----------
kind | Kind of target to add; one of 'git', 'url'.
url | URL of the Git repository.
branch | Branch of the Git repository.
repo | Vieter repository to publish built packages to.
schedule | Cron build schedule (syntax explained [here](https://rustybever.be/docs/vieter/usage/builds/schedule/))
arch | Comma-separated list of architectures to build package on.

## Modify a target

Modify the data of an existing target.

### HTTP Request

`PATCH /api/v1/targets/:id`

### URL Parameters

Parameter | Description
--------- | -----------
id | id of target to modify

### Query Parameters

Parameter | Description
--------- | -----------
kind | Kind of target; one of 'git', 'url'.
url | URL of the Git repository.
branch | Branch of the Git repository.
repo | Vieter repository to publish built packages to.
schedule | Cron build schedule
arch | Comma-separated list of architectures to build package on.

## Remove a target

Remove a target from the server.

### HTTP Request

`DELETE /api/v1/targets/:id`

### URL Parameters

Parameter | Description
--------- | -----------
id | id of target to remove
