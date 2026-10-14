// Clipboard history from Klipper's own database (Plasma 6: ~/.local/share/klipper/history3.sqlite, read-only; its
// D-Bus API gives text only): text AND images (Windows' Win+V shows both - Mario 2026-10-14), last-used times for the
// ago column, plus our own pins (~/.local/state/clockmost-shell/clip-pins.json). An item is a key: the text itself,
// or imgMark + Klipper's uuid for an image (its PNG is data/<uuid>/<data uuid>).
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var history: []
    property var pins: []
    property var used: ({}) // key -> ms, last used (Klipper)
    property var images: ({}) // image key -> PNG path
    readonly property string imgMark: "\u0001img:"
    readonly property string klipperDir: (Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share") + "/klipper"
    property bool watching: false // refresh while the tab is open
    // opened by Win+V: picking an item also pastes it into the app you were in (Windows). From the bar: copy only.
    property bool pasteOnPick: false
    property bool pastePending: false

    readonly property string pinsPath: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/clockmost-shell/clip-pins.json"

    function isImage(key) {
        return key.startsWith(imgMark);
    }

    function kind(text) {
        if (isImage(text)) return "IMG";
        const t = text.trim();
        if (/^#([0-9a-f]{3}|[0-9a-f]{6}|[0-9a-f]{8})$/i.test(t)) return "HEX";
        if (/^(https?:\/\/|www\.)\S+$/i.test(t) || /^[a-z0-9.-]+\.[a-z]{2,}\/\S*$/i.test(t)) return "URL";
        if (/^(sudo |git |ssh |cd |ls |cat |grep |journalctl |systemctl |docker |kubectl |cargo |uv |pacman |paru |curl |nmcli |qdbus|busctl |\$ |\.\/)/.test(t)
            || / \| |&&| --[a-z]/.test(t)) return "CMD";
        return "TXT";
    }

    function ago(text) {
        const t = used[text];
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
        // an image goes back as PNG via wl-copy (it forks and stays as the clipboard owner - output to /dev/null so it
        // doesn't hold our pipe open); Klipper sees it again and moves that item to the top
        if (isImage(text))
            setter.command = ["sh", "-c", "exec wl-copy --type image/png < \"$1\" >/dev/null 2>&1", "sh", images[text]];
        else
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
        command: ["sqlite3", "-readonly", "-json", root.klipperDir + "/history3.sqlite",
            "SELECT m.uuid AS id, m.text AS text, COALESCE(m.last_used_time, m.added_time) AS used, "
            + "(SELECT a.data_uuid FROM aux a WHERE a.uuid = m.uuid AND a.mimetype = 'image/png') AS png "
            + "FROM main m ORDER BY used DESC LIMIT 60"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const rows = text.trim() ? JSON.parse(text) : [];
                    const items = [], used = {}, images = {};
                    for (const r of rows) {
                        let key;
                        if (r.png) {
                            key = root.imgMark + r.id;
                            images[key] = root.klipperDir + "/data/" + r.id + "/" + r.png;
                        } else if (r.text && r.text.trim() !== "") {
                            key = r.text;
                        } else {
                            continue;
                        }
                        items.push(key);
                        used[key] = r.used * 1000;
                    }
                    root.used = used;
                    root.images = images;
                    root.history = items;
                } catch (e) {
                    console.warn("clipboard: can't read Klipper's history database", e);
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
