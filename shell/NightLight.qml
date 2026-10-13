// KWin night light: state from its D-Bus properties, on/off through kwinrc [NightColor] Active (what System
// Settings writes) - KWin's inhibit() only lasts as long as the calling connection, so it can't back a toggle.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool enabled: false
    property bool running: false

    function toggle() {
        setter.command = ["sh", "-c", "kwriteconfig6 --file kwinrc --group NightColor --key Active " + (!root.enabled)
            + " && qdbus6 org.kde.KWin /KWin reconfigure"];
        setter.running = true;
    }

    function refresh() {
        reader.running = true;
    }

    Process {
        id: reader
        command: ["sh", "-c", "for p in enabled running; do busctl --user get-property org.kde.KWin /org/kde/KWin/NightLight org.kde.KWin.NightLight $p; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = text.trim().split("\n");
                root.enabled = v[0] === "b true";
                root.running = v[1] === "b true";
            }
        }
    }
    Process {
        id: setter
        onExited: root.refresh()
    }
    Timer {
        interval: 10000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
