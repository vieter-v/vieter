# vim: ft=bash
# Maintainer: Jef Roosens

pkgbase='vieter'
pkgname='vieter'
pkgver='0.3.0_alpha.2'
pkgrel=1
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
}

package() {
    pkgdesc="Vieter is a lightweight implementation of an Arch repository server."

    install -dm755 "$pkgdir/usr/bin"
    install -Dm755 "$pkgname/pvieter" "$pkgdir/usr/bin/vieter"

    install -dm755 "$pkgdir/usr/share/man/man1"
    ./vieter man "$pkgdir/usr/share/man/man1"
}
