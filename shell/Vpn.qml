// VPN connections from NetworkManager (types vpn / wireguard); toggle = nmcli up/down.
// `name`/`active` = the first one, for the home tile; `connections` = all of them, for the network tab.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var connections: [] // [{name, type, active}]
    readonly property string name: connections.length ? connections[0].name : "" // empty = none configured
    readonly property bool active: connections.length ? connections[0].active : false

    function toggle(connName) {
        const c = connections.find(x => x.name === (connName ?? name));
        if (!c)
            return;
        setter.command = ["nmcli", "connection", c.active ? "down" : "up", c.name];
        setter.running = true;
    }

    function refresh() {
        reader.running = true;
    }

    Process {
        id: reader
        command: ["nmcli", "-t", "-f", "NAME,TYPE,ACTIVE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.connections = text.trim().split("\n").map(l => l.split(":"))
                    .filter(f => f[1] === "vpn" || f[1] === "wireguard")
                    .map(f => ({ name: f[0], type: f[1], active: f[2] === "yes" }));
            }
        }
    }
    Process {
        id: setter
        onExited: root.refresh()
    }
    Timer {
        interval: 10000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
