// App-tray menu state: which app's menu is open, where, and the submenu path (submenus open in place, with BACK).
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property bool open: false
    property string screenName: ""
    property real anchorX: -1 // screen x the panel centres under (the tray icon)
    property string title: ""
    property var stack: [] // QsMenuHandle / QsMenuEntry path: [root menu, submenu, ...]
    readonly property var current: stack.length ? stack[stack.length - 1] : null

    function show(item, screen, x) {
        if (open && stack.length && stack[0] === item.menu) {
            close(); // the same icon again = close
            return;
        }
        title = item.tooltipTitle || item.title || item.id;
        stack = [item.menu];
        screenName = screen ?? "";
        anchorX = x ?? -1;
        open = true;
    }
    function enter(entry) {
        stack = stack.concat([entry]);
    }
    function back() {
        if (stack.length > 1)
            stack = stack.slice(0, -1);
    }
    function close() {
        open = false;
    }
}
