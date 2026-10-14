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
    // opened by Win+V: picking an item also pastes it into the app you were in (Windows). From the bar: copy only.
    property bool pasteOnPick: false
    property bool pastePending: false

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

    // Win+V (KWin script -> bridge): the clipboard tab under the pointer, on the pointer's screen
    function openAtPointer(x, y) {
        const s = Quickshell.screens.find(s => x >= s.x && x < s.x + s.width && y >= s.y && y < s.y + s.height) ?? Quickshell.screens[0];
        if (ControlCenter.open && ControlCenter.tab === "clipboard") { // Win+V again closes it
            ControlCenter.close();
            return;
        }
        ControlCenter.show("clipboard", s?.name ?? "", x - (s?.x ?? 0));
        pasteOnPick = true; // after show: switching tabs clears it
    }

    function copy(text, paste) {
        pastePending = !!paste;
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
        onExited: {
            root.refresh();
            if (root.pastePending)
                pasteDelay.start();
        }
    }
    // the panel has closed and handed keyboard focus back by now; Ctrl+V comes from clockmost-autoscroll
    Timer {
        id: pasteDelay
        interval: 60
        onTriggered: {
            root.pastePending = false;
            Autoscroll.paste();
        }
    }
    Connections {
        target: KWin
        function onClipboardRequested(x, y) {
            root.openAtPointer(x, y);
        }
    }
    Connections {
        target: ControlCenter
        function onOpenChanged() {
            if (!ControlCenter.open)
                root.pasteOnPick = false;
        }
        function onTabChanged() {
            root.pasteOnPick = false;
        }
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
