# Vieter

{{< hint warning >}}
**Important**  
Because this project is still in heavy development, this documentation tries to
follow the development branch & not the latest release. This means that the
documentation might not be relevant anymore for the latest release.
{{< /hint >}}

## Overview

Vieter consists of two main parts, namely an implementation of an Arch
repository server & a scheduling system to periodically build Pacman packages &
publish them to a repository.

{{< hint info >}}
**Note**  
While I mention Vieter being an "Arch" repository server, it works with any
distribution that uses Pacman as the package manager. I do recommend using a
base docker image for your distribution if you wish to use the build system as
well.
{{< /hint >}}

### Why?

Vieter is my personal solution to a problem I've been facing for months:
extremely long AUR package build times. I run EndeavourOS on both my laptops,
one of which being a rather old MacBook Air. I really like being a beta-tester
for projects & run development builds for multiple packages (nheko,
newsflash...). Because of this, I have to regularly re-build these packages in
order to stay up to date with development. However, these builds can take a
really long time on the old MacBook. This project is a solution to that
problem: instead of building the packages locally, I can build them
automatically in the cloud & just download them whenever I update my system!
Thanks to this solution, I'm able to shave 10-15 minutes off my update times,
just from not having to compile everything every time there's an update.

Besides this, it's also just really useful to have a repository server that you
control & can upload your own packages to. For example, I package my st
terminal using a CI pipeline & upload it to my repository!

### Why V?

I had been interested in learning V for a couple of months ever since I
stumbled upon it by accident. It looked like a promising language & turned out
to be very fun to use! It's fast & easy to learn, & it's a nice contrast with
my usual Rust-based projects, which tend to get quite complex.

I recommend checking out their [homepage](https://vlang.io/)!

### What's with the name?

Before deciding to write this project in V, I wrote a prototype in Python,
called [Pieter](https://git.rustybever.be/Chewing_Bever/pieter). The name
Pieter came from Pieter Post, the Dutch name for [Postname
Pat](https://en.wikipedia.org/wiki/Postman_Pat). The idea was that the server
"delivered packages", & a good friend of mine suggested the name. When I
decided to switch over to Vieter, I changed the P (for Python) to a V, it
seemed fitting.
