# Maintainer: Benylin <lealmariop@gmail.com>
#
# Builds from $startdir (the pkgs/ CI checks out the tagged commit and runs makepkg in place).

pkgname=clockmost-shell
pkgver=0.2.10
pkgrel=2
pkgdesc="The clockmost desktop shell for KDE Plasma: v2 desktop layer (ground), bar, control center, dock, app drawer, notifications, Win+V clipboard (Quickshell)"
arch=('x86_64')
url="https://git.clockmost.com/pkgs/${pkgname}"
license=('MIT' 'OFL-1.1')  # OFL: the bundled Archivo font
depends=(
  'gcc-libs' 'glibc'
  'quickshell' 'qt6-websockets'  # the shell; the media tab's spectrum socket
  'sqlite' 'wl-clipboard'        # clipboard history: Klipper's database, putting images back
  'clevis'                       # the login's tang gate
)
makedepends=('rust' 'cargo' 'mold')
options=('!lto' '!debug')
install="${pkgname}.install"

prepare() {
  cd "$startdir"
  cargo fetch --locked --target "$(rustc -vV | sed -n 's/host: //p')"
}

build() {
  cd "$startdir"
  export RUSTFLAGS="-C link-arg=-fuse-ld=mold ${RUSTFLAGS:-}"
  export CARGO_TARGET_DIR=target
  cargo build --frozen --release
}

package() {
  cd "$startdir"
  install -Dm755 target/release/kwin-bridge "$pkgdir/usr/bin/kwin-bridge"
  install -Dm755 target/release/clockmost-autoscroll "$pkgdir/usr/bin/clockmost-autoscroll"

  # the Quickshell config: quickshell -p /usr/share/clockmost-shell
  install -d "$pkgdir/usr/share/clockmost-shell"
  cp -r --no-preserve=ownership shell/. "$pkgdir/usr/share/clockmost-shell/"
  find "$pkgdir/usr/share/clockmost-shell" -type f -exec chmod 644 {} +

  install -Dm644 install/clockmost-autoscroll.service "$pkgdir/usr/lib/systemd/system/clockmost-autoscroll.service"
  install -Dm644 install/clockmost-uinput.conf "$pkgdir/usr/lib/modules-load.d/clockmost-uinput.conf"
  install -Dm644 install/60-clockmost-uinput.rules "$pkgdir/usr/lib/udev/rules.d/60-clockmost-uinput.rules"
  install -Dm644 install/sddm-numlock.conf "$pkgdir/usr/lib/sddm/sddm.conf.d/zz-clockmost-numlock.conf"
  # the login (v2 stage 4): the SDDM theme + the tang gate pam_exec runs (wiring by hand: login/README.md)
  install -d "$pkgdir/usr/share/sddm/themes/clockmost"
  install -m644 login/sddm-theme/* "$pkgdir/usr/share/sddm/themes/clockmost/"
  install -Dm755 login/tang-gate "$pkgdir/usr/lib/clockmost-shell/tang-gate"
  install -Dm644 install/clockmost-shell.desktop "$pkgdir/etc/xdg/autostart/clockmost-shell.desktop"
  install -Dm644 install/org.clockmost.shell.desktop "$pkgdir/usr/share/applications/org.clockmost.shell.desktop"

  install -Dm755 install/clockmost-desktop-setup "$pkgdir/usr/bin/clockmost-desktop-setup"
  install -Dm644 install/setup.d/10-clockmost-shell.sh "$pkgdir/usr/share/clockmost-desktop/setup.d/10-clockmost-shell.sh"

  install -Dm644 LICENSE "$pkgdir/usr/share/licenses/$pkgname/LICENSE"
  install -Dm644 shell/assets/fonts/Archivo-OFL.txt "$pkgdir/usr/share/licenses/$pkgname/Archivo-OFL.txt"
  install -Dm644 README.md "$pkgdir/usr/share/doc/$pkgname/README.md"
}
