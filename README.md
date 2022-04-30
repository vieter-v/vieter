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

### Compiler

Vieter compiles with the standard Vlang compiler. However, I do maintain a
[mirror](https://git.rustybever.be/Chewing_Bever/v). This is to ensure my CI
does not break without reason, as I control when & how frequently the mirror is
updated to reflect the official repository.

## Features

* Arch repository server
    * Support for multiple repositories & multiple architectures
    * Endpoints for publishing new packages
    * API for managing repositories to build
* Build system
    * Periodic rebuilding of packages
    * Prevent unnecessary rebuilds

## Building

In order to build Vieter, you'll need a couple of libraries:

* An installation of V
* gc
* libarchive
* openssl

**NOTE**: if you encounter any issues compiling Vieter using the absolute
latest version of V, it might be because my mirror is missing a specific commit
that causes issues. For this reason, the `make v` command exists which will
clone my compiler in the `v` directory & build it. Afterwards, you can use this
compiler with make by prepending all make commands with `V_PATH=v/v`. If you do
encounter this issue, please let me know so I can update my mirror & the
codebase to fix it!
