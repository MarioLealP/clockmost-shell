// KWin desktops + windows, live from kwin-bridge (one JSON snapshot per line on its stdout).
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string current: ""
    property var desktops: [] // [{id, name, number}]
    property var windows: [] // [{id, app, title, desktops, onAll, active, minimized, attention}]

    readonly property var currentDesktop: desktops.find(d => d.id === current) ?? null

    function windowsOn(desktopId) {
        return windows.filter(w => w.onAll || w.desktops.includes(desktopId));
    }

    function switchTo(desktopId) {
        switcher.command = ["busctl", "--user", "set-property", "org.kde.KWin", "/VirtualDesktopManager",
            "org.kde.KWin.VirtualDesktopManager", "current", "s", desktopId];
        switcher.running = true;
    }

    Process {
        id: bridge
        command: [Quickshell.env("HOME") + "/.local/bin/kwin-bridge"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    const s = JSON.parse(line);
                    root.desktops = s.desktops;
                    root.windows = s.windows;
                    root.current = s.current;
                } catch (e) {
                    console.warn("kwin-bridge: bad line", e);
                }
            }
        }
        // keep the feed alive if the bridge dies (KWin restart, crash)
        onExited: restart.start()
    }

    Timer {
        id: restart
        interval: 2000
        onTriggered: bridge.running = true
    }

    Process {
        id: switcher
    }
}
