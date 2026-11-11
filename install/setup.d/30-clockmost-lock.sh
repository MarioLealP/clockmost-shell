#!/bin/bash
# The lock screen (desktop-environment-v2 item 15): kscreenlocker_greet loads its QML from the Plasma/Shell package
# named by PLASMA_DEFAULT_SHELL, read from KWin's environment (KWin starts the greeter). A drop-in on KWin's user unit
# sets it to org.clockmost.lock, so plasmashell keeps its own shell. Takes effect from the next login.
# Off switch: "lock" in ~/.config/clockmost/setup-off (the drop-in is removed, KDE's own lock screen is back).
set -eu
off() { grep -qsx "$1" "${XDG_CONFIG_HOME:-$HOME/.config}/clockmost/setup-off"; }
dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user/plasma-kwin_wayland.service.d"
dropin="$dir/clockmost-lock.conf"

if off lock; then
    if [ -e "$dropin" ]; then
        rm -f "$dropin"
        rmdir --ignore-fail-on-non-empty "$dir"
        systemctl --user daemon-reload 2>/dev/null || true
        echo "   lock off (setup-off): KDE's lock screen again from the next login"
    else
        echo "   lock off (setup-off): KDE's lock screen left alone"
    fi
    exit 0
fi

if [ ! -e /usr/share/plasma/shells/org.clockmost.lock/contents/lockscreen/LockScreen.qml ]; then
    echo "   lock screen: org.clockmost.lock not installed - left alone"
    exit 0
fi
mkdir -p "$dir"
printf '%s\n' \
    '# clockmost-desktop-setup (clockmost-shell, setup.d/30-clockmost-lock.sh): the clockmost lock screen.' \
    '# Off: a line "lock" in ~/.config/clockmost/setup-off, then clockmost-desktop-setup again.' \
    '[Service]' \
    'Environment=PLASMA_DEFAULT_SHELL=org.clockmost.lock' >"$dropin"
systemctl --user daemon-reload 2>/dev/null || true
echo "   lock screen: clockmost (from the next login)"
