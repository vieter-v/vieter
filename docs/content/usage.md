---
weight: 30
---
# Usage

## Starting the server

To start a server, either install it using Docker (see
[Installation](/installation)) or run it locally by executing `vieter
server`. See [Configuration](/configuration) for more information about
configuring the binary.

## Multiple repositories

Vieter works with multiple repositories. This means that a single Vieter server
can serve multiple repositories in Pacman. It also automatically divides files
with specific architectures among arch-repos. Arch-repos are the actual
repositories you add to your `/etc/pacman.conf` file. See [Configuring
Pacman](/usage#configuring-pacman) below for more info.

## Adding packages

Using Vieter is currently very simple. If you wish to add a package to Vieter,
build it using makepkg & POST that file to the `/<repo>/publish` endpoint of
your server. This will add the package to the repository. Authentification
requires you to add the API key as the `X-Api-Key` header.

All of this can be combined into a simple cURL call:

```
curl -XPOST -H "X-API-KEY: your-key" -T some-package.pkg.tar.zst https://example.com/somerepo/publish
```

`somerepo` is automatically created if it doesn't exist yet.

## Configuring Pacman

Configuring Pacman to use a Vieter instance is very simple. In your
`/etc/pacman.conf` file, add the following lines:

```
[vieter]
Server = https://example.com/$repo/$arch
SigLevel = Optional
```

Here, you see two important placeholder variables. `$repo` is replaced by the
name within the square brackets, which in this case would be `vieter`. `$arch`
is replaced by the output of `uname -m`. Because Vieter supports multiple
repositories & architectures per repository, using this notation makes sure you
always use the correct endpoint for fetching files.

I recommend placing this below all other repository entries, as the order
decides which repository should be used if there's ever a naming conflict.
