pragma Singleton
// (pragma first and alone on its line: Quickshell's scanner missed it below this longer header comment)
// The dock's state (ds-dock-v2): pinned apps (desktop ids in ~/.local/state/clockmost-shell/dock-pins.json), then any
// running app that isn't pinned. A slot = {key, entry, app, windows, active}. Windows are matched to desktop entries
// by their app class (KWin resourceClass) through DesktopEntries.heuristicLookup.
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // the mock's pins, where installed (Firefox, Discord, Spotify, Kitty, Dolphin, Steam, KeePassXC, Spectacle)
    readonly property var defaultPins: ["firefox", "discord", "equibop", "spotify", "kitty", "org.kde.dolphin", "steam",
        "org.keepassxc.KeePassXC", "org.kde.spectacle"]
    property var stored: null // the user's list from dock-pins.json, once there is one
    // keyed on the entries list (it notifies when the desktop files finish loading; byId alone doesn't)
    readonly property var pins: {
        const ids = new Set(DesktopEntries.applications.values.map(e => e.id));
        return (stored ?? defaultPins).filter(id => ids.has(id));
    }
    readonly property string pinsPath: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/clockmost-shell/dock-pins.json"

    function keyOf(w) {
        const e = DesktopEntries.heuristicLookup(w.app);
        return e ? e.id : (w.app || "").toLowerCase();
    }

    readonly property var slots: {
        const byKey = {};
        for (const w of KWin.windows) {
            const k = keyOf(w);
            (byKey[k] = byKey[k] || []).push(w);
        }
        const make = k => {
            const ws = byKey[k] || [];
            const entry = DesktopEntries.byId(k) ?? (ws.length ? DesktopEntries.heuristicLookup(ws[0].app) : null);
            return {
                key: k,
                entry: entry,
                app: ws.length ? ws[0].app : (entry?.startupClass || k),
                name: entry?.name ?? (ws.length ? ws[0].app : k),
                windows: ws,
                active: ws.some(w => w.active),
                pinned: root.pins.includes(k)
            };
        };
        const out = root.pins.map(make);
        for (const k of Object.keys(byKey))
            if (!root.pins.includes(k))
                out.push(make(k));
        return out;
    }
    readonly property int running: slots.filter(s => s.windows.length).length

    // the mock's two-letter codes: curated where the mock names them, else first letter + the next consonant
    readonly property var codes: ({ "firefox": "FX", "discord": "DC", "equibop": "DC", "spotify": "PH" })
    function code(s) {
        const k = s.key.toLowerCase();
        if (codes[k])
            return codes[k];
        const n = s.name.toUpperCase().replace(/[^A-Z]/g, "");
        const c = n.slice(1).match(/[BCDFGHJKLMNPQRSTVWXZ]/);
        return n.charAt(0) + (c ? c[0] : n.charAt(1));
    }

    // left click: launch / focus / minimize (cycles when the app has several windows); middle click: a new instance
    function activate(s) {
        if (!s.windows.length) {
            launch(s);
            return;
        }
        const i = s.windows.findIndex(w => w.active);
        if (i >= 0 && s.windows.length === 1)
            KWin.command("minimize", s.windows[0].id);
        else
            KWin.command("activate", s.windows[(i + 1) % s.windows.length].id);
    }
    function launch(s) {
        if (s.entry)
            Apps.launch(s.entry);
    }
    readonly property var pinnedSlots: slots.filter(s => s.pinned)
    readonly property var openSlots: slots.filter(s => !s.pinned)

    // right click (dock tile or drawer tile): pin / unpin by desktop id
    function isPinned(id) {
        return pins.includes(id);
    }
    function togglePin(id) {
        stored = isPinned(id) ? pins.filter(k => k !== id) : pins.concat([id]);
        pinsFile.setText(JSON.stringify(stored));
    }

    FileView {
        id: pinsFile
        path: root.pinsPath
        printErrors: false
        atomicWrites: true
        onLoaded: {
            try {
                const v = JSON.parse(text());
                if (Array.isArray(v))
                    root.stored = v;
            } catch (e) {}
        }
    }
}
