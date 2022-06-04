# Git Repositories

<aside class="notice">

All routes in this section require authentication.

</aside>

Endpoints for interacting with the list of Git repositories stored on the
server.

## List repos

```shell
curl \
  -H 'X-Api-Key: secret' \
  https://example.com/api/repos?offset=10&limit=20
```

> JSON output format

```json
{
  "message": "",
  "data": [
    {
      "id": 1,
      "url": "https://aur.archlinux.org/discord-ptb.git",
      "branch": "master",
      "repo": "bur",
      "schedule": "",
      "arch": [
        {
          "id": 1,
          "repo_id": 1,
          "value": "x86_64"
        }
      ]
    }
  ]
}
```

Retrieve a list of Git repositories.

### HTTP Request

`GET /api/repos`

### Query Parameters

Parameter | Description
--------- | -----------
limit | Maximum amount of results to return.
offset | Offset of results.
repo | Limit results to repositories that publish to the given repo.

## Get a repo

```shell
curl \
  -H 'X-Api-Key: secret' \
  https://example.com/api/repos/15
```

> JSON output format

```json
{
  "message": "",
  "data": {
    "id": 1,
    "url": "https://aur.archlinux.org/discord-ptb.git",
    "branch": "master",
    "repo": "bur",
    "schedule": "0 3",
    "arch": [
      {
        "id": 1,
        "repo_id": 1,
        "value": "x86_64"
      }
    ]
  }
}
```

Get info about a specific Git repository.

### HTTP Request

`GET /api/repos/:id`

### URL Parameters

Parameter | Description
--------- | -----------
id | ID of requested repo

## Create a new repo

Create a new Git repository with the given data.

### HTTP Request

`POST /api/repos`

### Query Parameters

Parameter | Description
--------- | -----------
url | URL of the Git repository.
branch | Branch of the Git repository.
repo | Vieter repository to publish built packages to.
schedule | Cron build schedule
arch | Comma-separated list of architectures to build package on.

## Modify a repo

Modify the data of an existing Git repository.

### HTTP Request

`PATCH /api/repos/:id`

### URL Parameters

Parameter | Description
--------- | -----------
id | ID of requested repo

### Query Parameters

Parameter | Description
--------- | -----------
url | URL of the Git repository.
branch | Branch of the Git repository.
repo | Vieter repository to publish built packages to.
schedule | Cron build schedule
arch | Comma-separated list of architectures to build package on.

## Remove a repo

Remove a Git repository from the server.

### HTTP Request

`DELETE /api/repos/:id`

### URL Parameters

Parameter | Description
--------- | -----------
id | ID of repo to remove
