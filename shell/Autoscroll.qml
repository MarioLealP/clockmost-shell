// The system-wide autoscroll's state (clockmost-autoscroll, autoscroll/): the service sends `start`,
// `dir <x> <y>`, `stop` over /run/clockmost-autoscroll/events; on start we ask KWin where the pointer is - that's
// the anchor the marker (AutoscrollMarker) is drawn at. On every middle press it sends `query <n>`: we ask KWin
// which app is under the pointer and answer `toggle <n>` (our autoscroll) only for whitelisted apps, else `pass <n>`
// - the middle button stays the app's (links, tabs, closing, drags; Mario 2026-10-14: "we do whitelist").
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool active: false
    property int dirX: 0
    property int dirY: 0
    property real x: 0 // anchor, global coordinates
    property real y: 0
    // apps that get our autoscroll, by window class (lowercase). Empty for now (Mario): Firefox and Spotify (the
    // phonograph) have their own; add an app here when it's missed. The shell's own layers never match.
    readonly property var autoscrollApps: []

    Socket {
        id: sock
        path: "/run/clockmost-autoscroll/events"
        connected: true
        onConnectedChanged: if (!connected) retry.start()
        parser: SplitParser {
            onRead: line => {
                const p = line.split(" ");
                if (p[0] === "query") {
                    if (root.autoscrollApps.length === 0) { // nothing listed: no need to ask KWin
                        sock.write("pass " + p[1] + "\n");
                        sock.flush();
                    } else {
                        KWin.command("cursor", "q" + p[1]);
                    }
                } else if (p[0] === "start") {
                    root.dirX = 0;
                    root.dirY = 0;
                    KWin.command("cursor", "");
                } else if (p[0] === "dir") {
                    root.dirX = +p[1];
                    root.dirY = +p[2];
                } else if (p[0] === "stop") {
                    root.active = false;
                }
            }
        }
    }
    // Ctrl+V into the focused app, pressed by the service's paste-only keyboard (Win+V clipboard history)
    function paste() {
        sock.write("paste\n");
        sock.flush();
    }

    // the service may start later / restart
    Timer {
        id: retry
        interval: 3000
        onTriggered: sock.connected = true
    }
    Connections {
        target: KWin
        function onCursorAt(x, y, app, tag) {
            if (tag.startsWith("q")) {
                const ours = root.autoscrollApps.includes(app.toLowerCase());
                sock.write((ours ? "toggle " : "pass ") + tag.slice(1) + "\n");
                sock.flush();
                return;
            }
            root.x = x;
            root.y = y;
            root.active = true;
        }
    }
}
