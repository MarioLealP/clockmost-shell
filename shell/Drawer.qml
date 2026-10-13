// App drawer state (ds-app-drawer): Win toggles it (with the bar), Esc / outside click / launching closes it.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    property bool open: false

    function toggle() {
        open = !open;
    }
    function close() {
        open = false;
    }
}
