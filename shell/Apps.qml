// Installed applications (the desktop's .desktop entries) for the drawer: ordered by how often they're
// launched (counts kept in ~/.local/state/clockmost-shell/app-usage.json), a category code per app.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var usage: ({}) // desktop id -> launch count
    readonly property string usagePath: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/clockmost-shell/app-usage.json"

    // plumbing that ships a .desktop file but nobody launches from a drawer (Qt dev tools, test/viewer utilities,
    // Avahi browsers, the old Noctalia launcher entry)
    readonly property var hidden: ["avahi-discover", "bssh", "bvnc", "assistant", "designer", "linguist", "qdbusviewer",
        "qv4l2", "qvidcap", "cmake-gui", "lstopo", "kitty-open", "dev.noctalia.Noctalia", "org.quickshell",
        "org.kde.kmenuedit", "limine-snapper-restore"]

    readonly property var all: DesktopEntries.applications.values
        .filter(e => !e.noDisplay && !hidden.includes(e.id))
        .slice()
        .sort((a, b) => (usage[b.id] || 0) - (usage[a.id] || 0) || a.name.localeCompare(b.name))

    function search(q) {
        const s = q.trim().toLowerCase();
        if (!s)
            return all;
        return all.filter(e => e.name.toLowerCase().includes(s) || (e.genericName || "").toLowerCase().includes(s)
            || (e.keywords || []).some(k => k.toLowerCase().includes(s)) || (e.id || "").toLowerCase().includes(s));
    }

    // the mock's three-letter codes (BRW, COM, MUS, TRM ...)
    function code(e) {
        const c = e.categories || [];
        const has = (...names) => names.some(n => c.includes(n));
        if (has("WebBrowser")) return "BRW";
        if (has("Chat", "InstantMessaging", "Telephony")) return "COM";
        if (has("Email")) return "MAL";
        if (has("Music", "Audio")) return "MUS";
        if (has("Video", "Player")) return "VID";
        if (has("TerminalEmulator")) return "TRM";
        if (has("Game")) return "GAM";
        if (has("FileManager")) return "FIL";
        if (has("Development", "IDE")) return "DEV";
        if (has("Security")) return "SEC";
        if (has("Graphics", "2DGraphics", "RasterGraphics", "VectorGraphics")) return "IMG";
        if (has("Office", "WordProcessor", "TextEditor")) return "DOC";
        if (has("Settings", "System")) return "SYS";
        if (has("Utility")) return "UTL";
        return "APP";
    }

    // Start a program in its own systemd scope (app-<name>-<time>.scope under app.slice), the way Plasma does, so it
    // never lives in the shell's unit: restarting or upgrading the shell can't take apps down with it.
    function run(command, name, workingDirectory) {
        const unit = "app-" + String(name || command[0]).replace(/[^A-Za-z0-9_.-]/g, "-") + "-" + Date.now();
        Quickshell.execDetached(["systemd-run", "--user", "--scope", "--collect", "--quiet", "--slice=app.slice", "--unit=" + unit, "--",
            "env", "-C", workingDirectory || Quickshell.env("HOME")].concat(command));
    }
    // a desktop entry or one of its actions; terminal apps open in kitty
    function exec(e, action) {
        const cmd = (action ?? e).command;
        run(e.runInTerminal ? ["kitty", "--"].concat(cmd) : cmd, e.id, e.workingDirectory);
    }

    function launch(e) {
        exec(e);
        const u = Object.assign({}, usage);
        u[e.id] = (u[e.id] || 0) + 1;
        usage = u;
        usageFile.setText(JSON.stringify(u));
    }

    FileView {
        id: usageFile
        path: root.usagePath
        printErrors: false
        atomicWrites: true
        onLoaded: {
            try {
                root.usage = JSON.parse(text());
            } catch (e) {
                root.usage = {};
            }
        }
    }
    Process {
        running: true
        command: ["mkdir", "-p", root.usagePath.replace(/\/[^/]+$/, "")]
    }
}
