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
