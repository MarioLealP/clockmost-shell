// Dock right-click menu state (Mario 2026-10-15: "windows context menu style" instead of right click = pin toggle):
// which slot's menu is open, on which screen, and the slot's centre x (window coordinates) the panel sits above.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property bool open: false
    property string screenName: ""
    property real anchorX: -1
    property var slot: null

    function show(slot, screen, x) {
        if (open && root.slot && root.slot.key === slot.key) {
            close(); // the same tile again = close
            return;
        }
        root.slot = slot;
        screenName = screen ?? "";
        anchorX = x ?? -1;
        open = true;
    }
    function close() {
        open = false;
    }
}
