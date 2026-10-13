// VPN state from NetworkManager: the first vpn/wireguard connection; toggle = nmcli up/down.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string name: "" // empty = no VPN connection configured
    property bool active: false

    function toggle() {
        if (!name)
            return;
        setter.command = ["nmcli", "connection", active ? "down" : "up", name];
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
                const vpn = text.trim().split("\n").map(l => l.split(":")).find(f => f[1] === "vpn" || f[1] === "wireguard");
                root.name = vpn ? vpn[0] : "";
                root.active = vpn ? vpn[2] === "yes" : false;
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
