// The system-wide autoscroll's state (clockmost-autoscroll, autoscroll/): the service sends `start`,
// `dir <x> <y>`, `stop` over /run/clockmost-autoscroll/events; on start we ask KWin where the pointer is - that's
// the anchor the marker (AutoscrollMarker) is drawn at. On a plain middle click it sends `query <n>`: we ask KWin
// which app is under the pointer and answer `toggle <n>` (Windows click-to-toggle autoscroll) or `pass <n>` for
// apps with their own autoscroll, which then get the click (Firefox, the phonograph).
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
    // apps that do their own (Windows-style) autoscroll, by window class
    readonly property var ownAutoscroll: ["firefox", "spotify"]

    Socket {
        id: sock
        path: "/run/clockmost-autoscroll/events"
        connected: true
        onConnectedChanged: if (!connected) retry.start()
        parser: SplitParser {
            onRead: line => {
                const p = line.split(" ");
                if (p[0] === "query") {
                    KWin.command("cursor", "q" + p[1]);
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
                const own = root.ownAutoscroll.includes(app.toLowerCase());
                sock.write((own ? "pass " : "toggle ") + tag.slice(1) + "\n");
                sock.flush();
                return;
            }
            root.x = x;
            root.y = y;
            root.active = true;
        }
    }
}
