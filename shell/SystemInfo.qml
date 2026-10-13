// user@host, uptime, kernel - for the control center header.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string user: Quickshell.env("USER") || "user"
    property string host: ""
    property string kernel: ""
    property int uptimeSeconds: 0

    readonly property string uptime: {
        const d = Math.floor(uptimeSeconds / 86400), h = Math.floor(uptimeSeconds % 86400 / 3600), m = Math.floor(uptimeSeconds % 3600 / 60);
        return d > 0 ? d + "D " + String(h).padStart(2, "0") + "H" : String(h).padStart(2, "0") + "H " + String(m).padStart(2, "0") + "M";
    }

    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: root.uptimeSeconds = Math.floor(parseFloat(text()))
    }
    FileView {
        path: "/proc/sys/kernel/hostname"
        onLoaded: root.host = text().trim()
    }
    FileView {
        path: "/proc/sys/kernel/osrelease"
        onLoaded: root.kernel = text().trim().toUpperCase()
    }
    Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: uptimeFile.reload()
    }
}
