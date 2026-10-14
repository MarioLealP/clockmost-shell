#!/bin/bash
# clockmost-shell's per-user settings (see clockmost-desktop-setup).
set -eu

# Win tap = reveal the bar (KWin modifier-only shortcut -> kwin-bridge)
kwriteconfig6 --file kwinrc --group ModifierOnlyShortcuts --key Meta \
    "org.clockmost.KWinBridge,/Bridge,org.clockmost.KWinBridge,Reveal"
qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
echo "   Win tap reveals the bar"

# Win+V = the shell's clipboard history: take Meta+V off Klipper's own popup (live, via KWin's shortcut service;
# falls back to the config file, read at the next login)
if busctl --user call org.kde.kglobalaccel /kglobalaccel org.kde.KGlobalAccel setForeignShortcutKeys 'asa(ai)' \
    4 plasmashell show-on-mouse-pos plasmashell "Show Clipboard Items at Mouse Position" 1 1 0 2>/dev/null; then
    echo "   Meta+V taken off Klipper"
else
    kwriteconfig6 --file kglobalshortcutsrc --group plasmashell --key show-on-mouse-pos \
        "none,Meta+V,Show Clipboard Items at Mouse Position"
    echo "   Meta+V taken off Klipper (from the next login)"
fi

# the dock's live previews: KWin grants window screencast only to apps listed in a .desktop file - refresh the cache
kbuildsycoca6 >/dev/null 2>&1 || true

# a dev autostart entry would start a second shell next to the packaged one
if grep -qs 'quickshell -p .*/src/clockmost-shell' "$HOME/.config/autostart/clockmost-shell.desktop"; then
    mv "$HOME/.config/autostart/clockmost-shell.desktop" "$HOME/.config/autostart/clockmost-shell.desktop.dev-off"
    echo "   dev autostart entry set aside (.dev-off)"
fi
