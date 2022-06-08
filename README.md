# Vieter

## Documentation

I host documentation for Vieter over at https://rustybever.be/docs/vieter/. API
documentation for the current codebase can be found at
https://rustybever.be/api-docs/vieter/.

## Overview

Vieter is a restart of the Pieter project. The goal is to create a simple,
lightweight self-hostable Arch repository server, paired with a system that
periodically builds & publishes select Arch packages. This would allow me to
build AUR packages (or PKGBUILDs I created myself) "in the cloud" & make sure I
never have to compile anything on my own systems, making my updates a lot
quicker.

## Why V?

I chose [V](https://vlang.io/) as I've been very intrigued by this language for
a while now. I wanted a fast language that I could code while relaxing, without
having to exert too much mental effort & V seemed like the right choice for
that.

## Features

* Arch repository server
    * Support for multiple repositories & multiple architectures
    * Endpoints for publishing new packages
    * API for managing repositories to build
* Build system
    * Periodic rebuilding of packages
    * Prevent unnecessary rebuilds

## Building

Besides a V installer, Vieter also requires the following libraries to work:

* gc
* libarchive
* openssl
* sqlite3

### Compiler

Vieter compiles with the standard Vlang compiler. However, I do maintain a
[mirror](https://git.rustybever.be/vieter/v). This is to ensure my CI does not
break without reason, as I control when & how frequently the mirror is updated
to reflect the official repository.

If you encounter issues using the latest V compiler, try using my mirror
instead. `make v` will clone the repository & build the mirror. Afterwards,
prepending any make command with `V_PATH=v/v` tells make to use the locally
compiled mirror instead.

## Contributing

If you wish to contribute to the project, please take note of the following:

* Rebase instead of merging whenever possible, e.g. when updating your branch
  with the dev branch.
* Please follow the
  [Conventional Commits](https://www.conventionalcommits.org/) style for your
  commit messages.

### Writing documentation

The `docs` directory contains a Hugo site consisting of all user &
administrator documentation. `docs/api` on the other hand is a
[Slate](https://github.com/slatedocs/slate) project describing the HTTP web
API.

To modify the Hugo documentation, you'll need to install Hugo. Afterwards, you
can use the following commands inside the `docs` directory:

```sh
# Build the documentation
hugo

# Host an auto-refreshing web server with the documentation. Important to note
# is that the files will be at `http://localhost:1313/docs/vieter` instead of
# just `http://localhost:1313/`
hugo server
```

For the Slate docs, I personally just start a docker container:

```sh
docker run \
    --rm \
    -p 4567:4567 \
    --name slate \
    -v $(pwd)/docs/api/source:/srv/slate/source slatedocs/slate serve
```

This will make the Slate docs available at http://localhost:4567. Sadly, this
server doesn't auto-refresh, so you'll have to manually refresh your browser
every time you make a change.
