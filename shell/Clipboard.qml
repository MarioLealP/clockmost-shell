// Clipboard history from Klipper (D-Bus; text only - Klipper exposes no images, timestamps or per-item delete),
// plus our own pins (~/.local/state/clockmost-shell/clip-pins.json) and "first seen" times for the ago column.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var history: []
    property var pins: []
    property var firstSeen: ({}) // text -> ms, for items seen since the shell started
    property bool watching: false // refresh while the tab is open

    readonly property string pinsPath: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/clockmost-shell/clip-pins.json"

    function kind(text) {
        const t = text.trim();
        if (/^#([0-9a-f]{3}|[0-9a-f]{6}|[0-9a-f]{8})$/i.test(t)) return "HEX";
        if (/^(https?:\/\/|www\.)\S+$/i.test(t) || /^[a-z0-9.-]+\.[a-z]{2,}\/\S*$/i.test(t)) return "URL";
        if (/^(sudo |git |ssh |cd |ls |cat |grep |journalctl |systemctl |docker |kubectl |cargo |uv |pacman |paru |curl |nmcli |qdbus|busctl |\$ |\.\/)/.test(t)
            || / \| |&&| --[a-z]/.test(t)) return "CMD";
        return "TXT";
    }

    function ago(text) {
        const t = firstSeen[text];
        if (!t) return "";
        const m = Math.floor((Date.now() - t) / 60000);
        return m < 1 ? "NOW" : m < 60 ? m + "M" : Math.floor(m / 60) + "H";
    }

    function copy(text) {
        setter.command = ["busctl", "--user", "call", "org.kde.klipper", "/klipper", "org.kde.klipper.klipper", "setClipboardContents", "s", text];
        setter.running = true;
    }

    function isPinned(text) {
        return pins.includes(text);
    }
    function togglePin(text) {
        pins = isPinned(text) ? pins.filter(p => p !== text) : pins.concat([text]);
        pinFile.setText(JSON.stringify(pins));
    }

    function refresh() {
        reader.running = true;
    }

    Process {
        id: reader
        command: ["busctl", "--user", "--json=short", "call", "org.kde.klipper", "/klipper", "org.kde.klipper.klipper", "getClipboardHistoryMenu"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const items = JSON.parse(text).data[0].filter(s => s.trim() !== "");
                    const seen = Object.assign({}, root.firstSeen);
                    const now = Date.now();
                    for (const s of items)
                        if (!seen[s]) seen[s] = now;
                    root.firstSeen = seen;
                    root.history = items;
                } catch (e) {
                    console.warn("clipboard: can't read Klipper history");
                }
            }
        }
    }
    Process {
        id: setter
        onExited: root.refresh()
    }

    FileView {
        id: pinFile
        path: root.pinsPath
        printErrors: false
        atomicWrites: true
        onLoaded: {
            try {
                root.pins = JSON.parse(text());
            } catch (e) {
                root.pins = [];
            }
        }
    }
    Process {
        // make sure the state dir exists before the first pin is written
        running: true
        command: ["mkdir", "-p", root.pinsPath.replace(/\/[^/]+$/, "")]
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 2000
        repeat: true
        running: root.watching
        onTriggered: root.refresh()
    }
}
