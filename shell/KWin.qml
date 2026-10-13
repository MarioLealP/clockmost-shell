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

    // a Win-key tap (KWin modifier-only shortcut -> bridge Reveal)
    signal revealRequested

    function windowsOn(desktopId) {
        return windows.filter(w => w.onAll || w.desktops.includes(desktopId));
    }

    function switchTo(desktopId) {
        switcher.command = ["busctl", "--user", "set-property", "org.kde.KWin", "/VirtualDesktopManager",
            "org.kde.KWin.VirtualDesktopManager", "current", "s", desktopId];
        switcher.running = true;
    }

    // window commands, run by the bridge's KWin script: "activate" (unminimize, switch desktop, focus) / "minimize"
    function command(op, id) {
        const p = cmdProc.createObject(root, {
            command: ["busctl", "--user", "call", "org.clockmost.KWinBridge", "/Bridge", "org.clockmost.KWinBridge",
                "Command", "s", JSON.stringify({ op: op, id: id })]
        });
        p.exited.connect(() => p.destroy());
        p.running = true;
    }
    Component {
        id: cmdProc
        Process {}
    }

    Process {
        id: bridge
        command: [Quickshell.env("HOME") + "/.local/bin/kwin-bridge"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    const s = JSON.parse(line);
                    if (s.event === "reveal") {
                        root.revealRequested();
                        return;
                    }
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
