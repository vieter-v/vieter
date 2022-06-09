# Builds In-depth

For those interested, this page describes how the build system works
internally.

## Builder image

Every cron daemon perodically creates a builder image that is then used as a
base for all builds. This is done to prevent build containers having to pull
down a bunch of updates when they update their system.

The build container is created by running the following commands inside a
container started from the image defined in `base_image`:

```sh
# Update repos & install required packages
pacman -Syu --needed --noconfirm base-devel git
# Add a non-root user to run makepkg
groupadd -g 1000 builder
useradd -mg builder builder
# Make sure they can use sudo without a password
echo 'builder ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
# Create the directory for the builds & make it writeable for the
# build user
mkdir /build
chown -R builder:builder /build
```

This script updates the packages to their latest versions & creates a non-root
user to use when running `makepkg`.

This script is base64-encoded & passed to the container as an environment
variable. The container's entrypoint is set to `/bin/sh -c` & its command
argument to `echo $BUILD_SCRIPT | base64 -d | /bin/sh -e`, with the
`BUILD_SCRIPT` environment variable containing the base64-encoded script.

Once the container exits, a new Docker image is created from it. This image is
then used as the base for any builds.

## Running builds

Each build has its own Docker container, using the builder image as its base.
The same base64-based technique as above is used, just with a different script.
To make the build logs more clear, each command is appended by an echo command
printing the next command to stdout.

Given the Git repository URL is `https://examplerepo.com` with branch `main`,
the URL of the Vieter server is `https://example.com` and `vieter` is the
repository we wish to publish to, we get the following script:

```sh
echo -e '+ echo -e '\''[vieter]\\nServer = https://example.com/$repo/$arch\\nSigLevel = Optional'\'' >> /etc/pacman.conf'
echo -e '[vieter]\nServer = https://example.com/$repo/$arch\nSigLevel = Optional' >> /etc/pacman.conf
echo -e '+ pacman -Syu --needed --noconfirm'
pacman -Syu --needed --noconfirm
echo -e '+ su builder'
su builder
echo -e '+ git clone --single-branch --depth 1 --branch main https://examplerepo.com repo'
git clone --single-branch --depth 1 --branch main https://examplerepo.com repo
echo -e '+ cd repo'
cd repo
echo -e '+ makepkg --nobuild --syncdeps --needed --noconfirm'
makepkg --nobuild --syncdeps --needed --noconfirm
echo -e '+ source PKGBUILD'
source PKGBUILD
echo -e '+ curl -s --head --fail https://example.com/vieter/x86_64/$pkgname-$pkgver-$pkgrel && exit 0'
curl -s --head --fail https://example.com/vieter/x86_64/$pkgname-$pkgver-$pkgrel && exit 0
echo -e '+ [ "$(id -u)" == 0 ] && exit 0'
[ "$(id -u)" == 0 ] && exit 0
echo -e '+ MAKEFLAGS="-j$(nproc)" makepkg -s --noconfirm --needed && for pkg in $(ls -1 *.pkg*); do curl -XPOST -T "$pkg" -H "X-API-KEY: $API_KEY" https://example.com/vieter/publish; done'
MAKEFLAGS="-j$(nproc)" makepkg -s --noconfirm --needed && for pkg in $(ls -1 *.pkg*); do curl -XPOST -T "$pkg" -H "X-API-KEY: $API_KEY" https://example.com/vieter/publish; done
```

This script:

1. Adds the target repository as a repository in the build container
2. Updates mirrors & packages
3. Clones the Git repository
4. Runs `makepkg` without building to calculate `pkgver`
5. Checks whether the package version is already present on the server
6. If not, run makepkg & publish any generated package archives to the server
