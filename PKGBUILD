# vim: ft=bash
# Maintainer: Jef Roosens

pkgbase='vieter'
pkgname='vieter'
pkgver='0.3.0'
pkgrel=1
pkgdesc="Vieter is a lightweight implementation of an Arch repository server."
depends=('glibc' 'openssl' 'libarchive' 'sqlite')
makedepends=('git' 'vieter-v')
arch=('x86_64' 'aarch64')
url='https://git.rustybever.be/vieter/vieter'
license=('AGPL3')
source=("$pkgname::git+https://git.rustybever.be/vieter/vieter#tag=${pkgver//_/-}")
md5sums=('SKIP')

build() {
    cd "$pkgname"

    make prod

    # The default CFLAGS for some reason causes vieter to segfault if used
    # inside the PKGBUILD. As a workaround, we use tcc to build a debug build
    # that does work, so we can generate the manpages.
    CFLAGS= LDFLAGS= make man
}

package() {
    install -dm755 "$pkgdir/usr/bin"
    install -Dm755 "$pkgname/pvieter" "$pkgdir/usr/bin/vieter"

    install -dm755 "$pkgdir/usr/share/man/man1"
    install -Dm644 "$pkgname/man"/*.1 "$pkgdir/usr/share/man/man1"
}
