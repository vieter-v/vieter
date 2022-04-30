# API Reference

All routes that return JSON use the following shape:

```json
{
    "message": "some message",
    "data": {}
}
```

Here, data can be any JSON object, so it's not guaranteed to be a struct.

### `GET /<repo>/<arch>/<filename>`

This route serves the contents of a specific architecture' repo.

If `<filename>` is one of `<repo>.db`, `<repo>.files`, `<repo>.db.tar.gz` or
`<repo>.files.tar.gz`, it will serve the respective archive file from the
repository.

If `<filename>` contains `.pkg`, it assumes the request to be for a package
archive & will serve that file from the specific arch-repo's package directory.

Finally, if none of the above are true, Vieter assumes it  to be request for a
package version's desc file & tries to serve this instead. This functionality
is very useful for the build system for checking whether a package needs to be
rebuilt or not.

### `HEAD /<repo>/<arch>/<filename>`

Behaves the same as the above route, but instead of returning actual data, it
returns either 200 or 404, depending on whether the file exists. This route is
used by the build system to determine whether a package needs to be rebuilt.

### `POST /<repo>/publish`

This route is used to upload packages to a repository. It requires the API
key to be provided using the `X-Api-Key` HTTP header. Vieter will parse the
package's contents & update the repository files accordingely. I find the
easiest way to use this route is using cURL:

```sh
curl -XPOST -T "path-to-package.pkg.tar.zst" -H "X-API-KEY: your-api-key" https://example.com/somerepo/publish
```

Packages are automatically added to the correct arch-repo. If a package type is
`any`, the package is added to the configured `default_arch`, as well as all
already present arch-repos. To prevent unnecessary duplication of package
files, these packages are shared between arch-repos' package directories using
hard links.

{{< hint info >}}
**Note**  
Vieter only supports uploading archives compressed using either gzip, zstd or
xz at the moment.
{{< /hint >}}

## API

All API routes require the API key to provided using the `X-Api-Key` header.
Otherwise, they'll return a status code 401.

### `GET /api/repos`

Returns the current list of Git repositories.

### `GET /api/repos/<id>`

Get the information for the Git repo with the given ID.

### `POST /api/repos?<url>&<branch>&<arch>&<repo>`

Adds a new Git repository with the provided URL, Git branch & comma-separated
list of architectures.

### `DELETE /api/repos/<id>`

Deletes the Git repository with the provided ID.

### `PATCH /api/repos/<id>?<url>&<branch>&<arch>&<repo>`

Updates the provided parameters for the repo with the given ID. All arguments
are optional.
