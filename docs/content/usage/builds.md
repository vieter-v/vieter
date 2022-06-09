---
weight: 20
---
# Building packages

The automatic build system is what makes Vieter very useful as a replacement
for an AUR helper. It can perodically build packages & publish them to your
personal Vieter repository server, removing the need to build the packages
locally.

## Adding builds

Before the cron system can start building your package, you need to add its
info to the system. The Vieter repository server exposes an HTTP API for this
(see the [HTTP API Docs](https://rustybever.be/docs/vieter/api/) for more
info). For ease of use, the Vieter binary contains a CLI interface for
interacting with this API (see [Configuration](/configuration) for
configuration details). The [man
pages](https://rustybever.be/man/vieter/vieter-repos.1.html) describe this in
greater detail, but the basic usage is as follows:

```
vieter repos add some-url some-branch some-repository
```

Here, `some-url` is the URL of the Git repository containing the PKGBUILD. This
URL is passed to `git clone`, so the repository should be public. Vieter
expects the same format as an AUR Git repository, so you can directly use AUR
URLs here.

`some-branch` is the branch of the Git repository the build should check out.
If you're using an AUR package, this should be `master`.

Finally, `some-repo` is the repository to which the built package archives
should be published.

The above command intentionally leaves out a few parameters to make the CLI
more useable. For information on how to modify all parameters using the CLI,
see
[vieter-repos-edit(1)](https://rustybever.be/man/vieter/vieter-repos-edit.1.html).
