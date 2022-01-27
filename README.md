# Vieter

Vieter is a re-implementation of the Pieter project. The goal is to create a
simple PKGBUILD-based build system, combined with a self-hosted Arch
repository. This would allow me to periodically re-build AUR packages (or
PKGBUILDs I created myself), & make sure I never have to compile anything on my
own systems, making my updates a lot quicker.

## Why V?

I chose [V](https://vlang.io/) as I've been very intrigued by this language for
a while now. I wanted a fast language that I could code while relaxing, without
having to exert too much mental effort & V seemed like the right choice for
that.

### Custom Compiler

Currently, this program only works with a very slightly modified version of the
V standard library, and therefore the compiler. The code for this can be found
[here](https://github.com/ChewingBever/v). For CI purposes & ease of use, you
can also clone & build that repo locally by running `make customv`.

## Features

The project will consist of a server-agent model, where one or more builder
nodes can register with the server. These agents communicate with the Docker
daemon to start builds, which are then uploaded to the server's repository. The
server also allows for non-agents to upload packages, as long as they have the
required secrets. This allows me to also develop non-git packages, such as my
terminal, & upload them to the servers using CI.

## Directory Structure

The data directory consists of three main directories:

* `downloads` - This is where packages are initially downloaded. Because vieter
  moves files from this folder to the `pkgs` folder, these two folders should
  best be on the same drive
* `pkgs` - This is where approved package files are stored.
* `repos` - Each repository gets a subfolder here. The subfolder contains the
  uncompressed contents of the db file.
    * Each repo subdirectory contains the compressed db & files archive for the
      repository, alongside a directory called `files` which contains the
      uncompressed contents.
