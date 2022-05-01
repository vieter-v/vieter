---
weight: 10
---
# Installation

## Docker

Docker is the recommended way to install vieter. The images can be pulled from
[`chewingbever/vieter`](https://hub.docker.com/r/chewingbever/vieter). You can
either pull a release tag (e.g. `chewingbever/vieter:0.1.0-rc1`), or pull the
`chewingbever/vieter:dev` tag. The latter is updated every time a new commit is
pushed to the development branch. This branch will be the most up to date, but
does not give any guarantees about stability, so beware!

The simplest way to run the Docker image is using a plain Docker command:

```sh
docker run \
    --rm \
    -d \
    -v /path/to/data:/data \
    -e VIETER_API_KEY=changeme \
    -e VIETER_DEFAULT_ARCH=x86_64 \
    -p 8000:8000 \
    chewingbever/vieter:dev
```

Here, you should change `/path/to/data` to the path on your host where you want
vieter to store its files.

The default configuration will store everything inside the `/data` directory.

Inside the container, the Vieter server runs on port 8000. This port should be
exposed to the public accordingely.

For an overview of how to configure vieter & which environment variables can be
used, see the [Configuration](/configuration) page.

## Binary

On the [releases](https://git.rustybever.be/Chewing_Bever/vieter/releases)
page, you can find statically compiled binaries for all released versions. You
can download the binary for your host's architecture & run it that way.

For more information about configuring the binary, check out the
[Configuration](/configuration) page.

## Building from source

Because the project is still in heavy development, it might be useful to build
from source instead. Luckily, this process is very easy. You'll need make,
libarchive & openssl; all of which should be present on an every-day Arch
install. Then, after cloning the repository, you can use the following commands:

```sh
# Builds the compiler; should usually only be ran once. Vieter compiles using
# the default compiler, but I maintain my own mirror to ensure nothing breaks
# without me knowing.
make v

# Build vieter
# Alternatively, use `make prod` to build the production build.
make
```
{{< hint info >}}
**Note**  
My version of the V compiler is also available on my Vieter instance,
https://arch.r8r.be. It's in the `vieter` repository, with the package being
named `vieter-v`. The compiler is available for both x86_64 & aarch64.
{{< /hint >}}

## My Vieter instance

Besides uploading development Docker images, my CI also publishes x86_64 &
aarch64 packages to my personal Vieter instance, https://arch.r8r.be. If you'd
like, you can use this repository as well by adding it to your Pacman
configuration as described [here](/usage#configuring-pacman). Both the
repository & the package are called `vieter`.
