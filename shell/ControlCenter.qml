// Control center state: one panel with a tab rail (Noctalia-style). Bar widgets open it on their tab.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var tabs: [
        { id: "home", label: "HOME", icon: "home" },
        { id: "audio", label: "AUDIO", icon: "volume" },
        { id: "network", label: "NETWORK", icon: "ethernet" },
        { id: "bluetooth", label: "BLUETOOTH", icon: "bluetooth" },
        { id: "media", label: "MEDIA", icon: "media" },
        { id: "calendar", label: "CALENDAR", icon: "calendar" },
        { id: "notifications", label: "NOTIFICATIONS", icon: "bell" },
        { id: "clipboard", label: "CLIPBOARD", icon: "clipboard" }
    ]

    property bool open: false
    property string tab: "home"
    property string screenName: "" // the panel opens on the screen whose bar was used

    // same widget again = close (the mock: "click the open icon again")
    function toggle(tabId, screen) {
        if (open && tab === tabId) {
            open = false;
        } else {
            show(tabId, screen);
        }
    }

    function show(tabId, screen) {
        tab = tabId;
        if (screen)
            screenName = screen;
        open = true;
    }

    function close() {
        open = false;
    }
}
