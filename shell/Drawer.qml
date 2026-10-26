// App drawer state (ds-app-drawer): Win toggles it (with the bar), Esc / outside click / launching closes it.
// "Outside" includes the bar and the dock (Windows' Start menu): they stay usable while it's open, and pressing them
// closes it (DrawerCloser) - the press goes on to them, so the dock's drawer button mustn't reopen it right away.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    property bool open: false
    property real closedAt: 0
    signal stepRequested(int d) // IPC `drawer step <n>`: walk the deck without a keyboard (testing)

    function toggle() {
        if (!open && Date.now() - closedAt < 400)
            return;
        open = !open;
    }
    function close() {
        if (open)
            closedAt = Date.now();
        open = false;
    }

    // the screen strips the drawer's click catchers leave to the bar (band + clock plate) and the dock plate
    function topInset(screenWidth) {
        return Math.ceil((Theme.plateHeight + Theme.triBand) * Math.min(1, screenWidth / 1920));
    }
    function bottomInset(screenWidth) {
        return Math.ceil((Theme.dockPlateHeight + Theme.dockGapBottom) * Math.min(1, screenWidth / 1920));
    }
}
