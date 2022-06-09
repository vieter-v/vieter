---
weight: 10
---
# Pacman repository

The part of Vieter that users will interact with the most is the Pacman
repository aka `vieter server`.

## Design overview

A Vieter repository server has support for multiple repositories, with each
repository containing packages for multiple architectures.

If you wish to use these repositories on your system, add the following to
`/etc/pacman.conf` for each repository you wish to use:

```
[repo-name]
Server = https://example.com/$repo/$arch
SigLevel = Optional
```

Here, `$repo` and `$arch` are not variables you have to fill in yourself.
Rather, Pacman will substitute these when reading the config file. `$repo` is
replaced by the name between the square brackets (in this case `repo-name`),
and `$arch` is replaced by your system's architecture, e.g. `x86_64`. Of
course, you can also fill in these values manually yourself, e.g. if you wish
to use a different name inside the square brackets.

Important to note is that, when two repositories contain a package with the
same name, Pacman will choose the one from the repository that's highest up in
the `pacman.conf` file. Therefore, if you know your repository has packages
with the same name as ones from the official repositories, it might be better
to place the repository below the official repositories to avoid overwriting
official packages.

## Publishing packages

Packages can be easily published using a single HTTP POST request. Check out
the [HTTP API docs](https://rustybever.be/docs/vieter/api/) for more info on
these routes, including example cURL commands.
