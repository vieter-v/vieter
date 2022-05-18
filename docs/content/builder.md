# Builder

Vieter supports a basic build system that allows you to build the packages
defined using the Git repositories API by running `vieter build`. For
configuration, see [here](/configuration#builder).

## How it works

The build system works in two stages. First it pulls down the
`archlinux:latest` image from Docker Hub, runs `pacman -Syu` & configures a
non-root build user. It then creates a new Docker image from this container.
This is to prevent each build having to fully update the container's
repositories. After the image has been created, each repository returned by
`/api/repos` is built sequentially by starting up a new container with the
previously created image as a base. Each container goes through the following steps:

1. The repository is cloned
2. `makepkg --nobuild --syncdeps --needed --noconfirm` is ran to update the `pkgver` variable inside
   the `PKGBUILD` file
3. A HEAD request is sent to the Vieter server to check whether the specific
   version of the package is already present. If it is, the container exits.
4. `makepkg` is ran with `MAKEFLAGS="-j\$(nproc)`
5. Each produced package archive is uploaded to the Vieter instance's
   repository, as defined in the API for that specific Git repo.

## Cron image

The Vieter Docker image contains crond & a cron config that runs `vieter build`
every night at 3AM. This value is currently hardcoded, but I wish to change
that down the line (work is in progress). There's also some other caveats you
should be aware of, namely that the image should be run as root & that the
healthcheck will always fail, so you might have to disable it. This boils down
to the following docker-compose file:

```yaml
version: '3'

services:
  cron:
    image: 'chewingbever/vieter:dev'
    command: crond -f
    user: root

    healthcheck:
      disable: true
        
    environment:
      - 'VIETER_API_KEY=some-key'
      - 'VIETER_ADDRESS=https://example.com'
    volumes:
      - '/var/run/docker.sock:/var/run/docker.sock'
```

Important to note is that the container also requires the host's Docker socket
to be mounted as this is how it spawns the necessary containers, as well as a
change to the container's command.
