// Window-mark colour per app - the mock's palette (ds-topbar-v2 workspace chips).
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
            "clockmost": "#FFFA00"
        })
    readonly property var palette: ["#7ddb57", "#ff7a1a", "#cfc6f4", "#5aa7ff", "#ff1aac", "#3FD0E8"]

    function of(app) {
        const key = (app || "").toLowerCase();
        if (known[key])
            return known[key];
        // unknown apps get a stable colour from the same palette
        let h = 0;
        for (let i = 0; i < key.length; i++)
            h = (h * 31 + key.charCodeAt(i)) >>> 0;
        return palette[h % palette.length];
    }
}
