# Maintainer: Jef Roosens

pkgbase='vieter'
pkgname='vieter'
pkgver=0.2.0.r25.g20112b8
pkgrel=1
depends=('glibc' 'openssl' 'libarchive' 'gc' 'sqlite')
makedepends=('git' 'gcc' 'vieter-v')
arch=('x86_64' 'aarch64')
url='https://git.rustybever.be/vieter/vieter'
license=('AGPL3')
source=($pkgname::git+https://git.rustybever.be/vieter/vieter#branch=dev)
md5sums=('SKIP')

pkgver() {
    cd "$pkgname"

    git describe --long --tags | sed 's/^v//;s/\([^-]*-g\)/r\1/;s/-/./g'
}

build() {
    cd "$pkgname"

    make prod
}

package() {
    pkgdesc="Vieter is a lightweight implementation of an Arch repository server."

    install -dm755 "$pkgdir/usr/bin"
    install -Dm755 "$pkgbase/pvieter" "$pkgdir/usr/bin/vieter"
}
