# Maintainer: Jef Roosens

pkgbase='vieter'
pkgname='vieter'
pkgver=0.1.0.rc1.r45.g6d3ff8a
pkgrel=1
depends=('glibc' 'openssl' 'libarchive' 'gc')
makedepends=('git' 'gcc')
arch=('x86_64' 'aarch64' 'armv7')
url='https://git.rustybever.be/Chewing_Bever/vieter'
license=('AGPL3')
source=($pkgname::git+https://git.rustybever.be/Chewing_Bever/vieter#branch=dev)
md5sums=('SKIP')

pkgver() {
    cd "$pkgname"
    git describe --long --tags | sed 's/^v//;s/\([^-]*-g\)/r\1/;s/-/./g'
}

build() {
    cd "$pkgname"

    # Build the compiler
    CFLAGS= make v

    make prod
}

package() {
    pkgdesc="Vieter is a lightweight implementation of an Arch repository server."
    install -dm755 "$pkgdir/usr/bin"

    install -Dm755 "$pkgbase/pvieter" "$pkgdir/usr/bin/vieter"
}
