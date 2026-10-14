// The system-wide autoscroll's state (clockmost-autoscroll, autoscroll/): the service sends `start`,
// `dir <x> <y>`, `stop` over /run/clockmost-autoscroll/events; on start we ask KWin where the pointer is - that's
// the anchor the marker (AutoscrollMarker) is drawn at.
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

    Socket {
        id: sock
        path: "/run/clockmost-autoscroll/events"
        connected: true
        onConnectedChanged: if (!connected) retry.start()
        parser: SplitParser {
            onRead: line => {
                const p = line.split(" ");
                if (p[0] === "start") {
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
        function onCursorAt(x, y) {
            root.x = x;
            root.y = y;
            root.active = true;
        }
    }
}
