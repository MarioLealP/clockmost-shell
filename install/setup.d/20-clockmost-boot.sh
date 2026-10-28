#!/bin/bash
# The boot, from the login to the desktop, in one colour (desktop-environment-v2 stage 5): KDE's startup splash is
# clockmost's plain graphite one, and Plasma's own desktop (under the shell's ground) is that graphite too, so nothing
# else shows while the shell starts. Off switch: "boot" in ~/.config/clockmost/setup-off.
set -eu
off() { grep -qsx "$1" "${XDG_CONFIG_HOME:-$HOME/.config}/clockmost/setup-off"; }
if off boot; then
    echo "   boot off (setup-off): splash + Plasma wallpaper left alone"
    exit 0
fi

kwriteconfig6 --file ksplashrc --group KSplash --key Engine KSplashQML
kwriteconfig6 --file ksplashrc --group KSplash --key Theme org.clockmost.splash
echo "   startup splash: clockmost graphite"

if qdbus6 org.kde.plasmashell /PlasmaShell evaluateScript '
    desktops().forEach(function (d) {
        d.wallpaperPlugin = "org.kde.color";
        d.currentConfigGroup = ["Wallpaper", "org.kde.color", "General"];
        d.writeConfig("Color", "#1a1a18");
    });' >/dev/null 2>&1; then
    echo "   Plasma desktop under the ground: graphite"
else
    echo "   Plasma desktop: plasmashell not reachable - re-run inside the Plasma session"
fi
