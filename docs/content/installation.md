---
weight: 10
---
# Installation

Vieter consists of a single binary, akin to busybox. The binary's behavior is
determined by its CLI arguments, e.g. `vieter server` starts the repository
server.

All installation solutions can be configured the same way,
as described [here](/configuration).

## Docker

Docker images are published to the
[`chewingbever/vieter`](https://hub.docker.com/r/chewingbever/vieter) Docker
Hub repository. You can either pull a release tag (e.g.
`chewingbever/vieter:0.1.0-rc1`), or pull the `chewingbever/vieter:dev` tag.
The latter is updated every time a new commit is pushed to the development
branch. This branch will be the most up to date, but does not give any
guarantees about stability, so beware!

Thanks to the single-binary design of Vieter, this image can be used both for
the repository server, the cron daemon and the agent.

Below is an example compose file to set up both the repository server & the
cron daemon:

```yaml
version: '3'

services:
  server:
    image: 'chewingbever/vieter:dev'
    restart: 'always'

    environment:
      - 'VIETER_API_KEY=secret'
      - 'VIETER_DEFAULT_ARCH=x86_64'
    volumes:
      - 'data:/data'

  cron:
    image: 'chewingbever/vieter:dev'
    restart: 'always'
    user: root
    command: 'vieter cron'

    environment:
      - 'VIETER_API_KEY=secret'
      # MUST be public URL of Vieter repository
      - 'VIETER_ADDRESS=https://example.com'
      - 'VIETER_DEFAULT_ARCH=x86_64'
      - 'VIETER_MAX_CONCURRENT_BUILDS=2'
      - 'VIETER_GLOBAL_SCHEDULE=0 3'
    volumes:
      - '/var/run/docker.sock:/var/run/docker.sock'

volumes:
  data:
```

If you do not require the build system, the repository server can be used
independently as well.

{{< hint info >}}
**Note**  
Builds are executed on the cron daemon's system using the host's Docker daemon.
A cron daemon on a specific architecture will only build packages for that
specific architecture. Therefore, if you wish to build packages for both
`x86_64` & `aarch64`, you'll have to deploy two cron daemons, one on each
architecture. Afterwards, any Git repositories enabled for those two
architectures will build on both.
{{< /hint >}}

## Binary

On the
[releases](https://git.rustybever.be/vieter-v/vieter/releases)
page, you can find statically compiled binaries for all
released versions. This is the same binary as used inside
the Docker images.

## Arch

I publish both development & release versions of Vieter to my personal
repository, https://arch.r8r.be. Packages are available for `x86_64` &
`aarch64`. To use the repository, add the following to your `pacman.conf`:

```
[vieter]
Server = https://arch.r8r.be/$repo/$arch
SigLevel = Optional
```

Afterwards, you can update your system & install the `vieter` package for the
latest official release or `vieter-git` for the latest development release.

### AUR

If you prefer building the packages locally (or on your own Vieter instance),
there's the `[vieter](https://aur.archlinux.org/packages/vieter)` &
`[vieter-git](https://aur.archlinux.org/packages/vieter-git)` packages on the
AUR. These packages build using the `vlang-git` compiler package, so I can't
guarantee that a compiler update won't temporarily break them.

## Building from source

The project [README](https://git.rustybever.be/vieter-v/vieter#building)
contains instructions for building Vieter from source.
