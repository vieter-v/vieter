# Repository

Besides providing a RESTful API, the Vieter server is also a Pacman-compatible
repository server. This section describes the various routes that make this
possible.

## Get a package archive or database file

```shell
curl -L https://example.com/bur/x86_64/tuxedo-keyboard-3.0.10-1-x86_64.pkg.tar.zst
```

This endpoint is really the entire repository. It serves both the package
archives & the database files for a specific arch-repo. It has three different
behaviors, depending on `filename`:

* If the file extension is one of `.db`, `.files`, `.db.tar.gz` or
  `.files.tar.gz`, it tries to serve the requested database file.
* If the filename contains `.pkg`, it serves the package file.
* Otherwise, it assumes `filename` is the name & version of a package inside
  the repository (e.g. `vieter-0.3.0_alpha.2-1`) & serves that package's `desc`
  file from inside the database archive.

<aside class="notice">

The final option might sound a little strange, but it's used by the build
system to determine whether a package needs to be rebuilt.

</aside>

### HTTP Request

`GET /:repo/:arch/:filename`

### URL Parameters

Parameter | Description
--------- | -----------
repo | Repository containing the package
arch | Arch-repo containing the package
filename | actual filename to request

## Check whether file exists

```shell
curl -L https://example.com/bur/x86_64/tuxedo-keyboard-3.0.10-1-x86_64.pkg.tar.zst
```

The above request can also be performed as a HEAD request. The behavior is the
same, except no data is returned besides an error 404 if the file doesn't exist
& an error 200 otherwise.

### HTTP Request

`GET /:repo/:arch/:filename`

### URL Parameters

Parameter | Description
--------- | -----------
repo | Repository containing the package
arch | Arch-repo containing the package
filename | actual filename to request

## Publish package

<aside class="notice">

This endpoint requests authentication.

</aside>

```shell
curl \
  -H 'X-Api-Key: secret' \
  -XPOST \
  -T tuxedo-keyboard-3.0.10-1-x86_64.pkg.tar.zst \
  https://example.com/some-repo/publish
```

This endpoint allows you to publish a new package archive to a given repo.

If the package's architecture is not `any`, it is added to that specific
arch-repo. Otherwise, it is added to the configured default architecture & any
other already present arch-repos.

### HTTP Request

`POST /:repo/publish`

### URL Parameters

Parameter | Description
--------- | -----------
repo | Repository to publish package to
