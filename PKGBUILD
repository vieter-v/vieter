# Maintainer: Jef Roosens

pkgbase='vieter'
pkgname=('vieter' 'vieterctl')
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

    # Build the server & the CLI tool
    make prod
    make cli-prod
}

package_vieter() {
    install -dm755 "$pkgdir/usr/bin"

    install -Dm755 "$pkgbase/pvieter" "$pkgdir/usr/bin/vieter"
}

package_vieterctl() {
    install -dm755 "$pkgdir/usr/bin"

    install -Dm755 "$pkgbase/vieterctl" "$pkgdir/usr/bin/vieterctl"
}
