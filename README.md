# Vieter

## Documentation

I host documentation for Vieter over at https://rustybever.be/docs/vieter.

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

### Custom Compiler

Currently, this program only works with a very slightly modified version of the
V standard library, and therefore the compiler. The source code for this fork
can be found [here](https://git.rustybever.be/Chewing_Bever/vieter-v). You can
obtain this modified version of the compiler by running `make v`, which will
clone & build the compiler. Afterwards, all make commands that require the V
compiler will use this new binary. I try to keep this fork as up to date with
upstream as possible.

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

* gc
* libarchive
* openssl

Before building Vieter, you'll have to build the compiler using `make v`.
Afterwards, run `make` to build the debug binary.
