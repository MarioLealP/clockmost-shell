// Window-mark colour per app. v2: all bone (one loud colour); the old Endfield palette is kept below, unused.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property var known: ({
            "kitty": "#7ddb57",
            "firefox": "#ff7a1a",
            "equibop": "#5aa7ff",
            "vesktop": "#5aa7ff",
            "discord": "#5aa7ff",
            "spotify": "#cfc6f4",
            "dolphin": "#3FD0E8",
            "felt": "#ff1aac",
            "spectacle": "#ff1aac",
            "downloads": "#7ddb57",
            "zabbix": "#d91e36",
            "clockmost": "#ff5f1f"
        })
    readonly property var palette: ["#7ddb57", "#ff7a1a", "#cfc6f4", "#5aa7ff", "#ff1aac", "#3FD0E8"]

    // v2 (2026-10-25): one loud colour - every app's mark is bone; the table above is kept for a future per-app tint
    function of(app) {
        return "#c9c7c0";
    }
}
