// Control center NETWORK tab: wired connection details (from NetworkManager), Wi-Fi when a Wi-Fi device exists,
// and every VPN with a switch. v2 mock: clockmost-desktop design/v2-2026-10-25/cc.html?tab=network.
import QtQuick
import Quickshell.Io
import Quickshell.Networking

CCTab {
    id: root

    readonly property var devices: Networking.devices.values
    readonly property var wiredDevices: devices.filter(d => d.type === DeviceType.Wired)
    readonly property var wifiDevices: devices.filter(d => d.type === DeviceType.Wifi)
    readonly property var wired: wiredDevices[0] ?? null
    readonly property var wifi: wifiDevices[0] ?? null
    readonly property var wifiNetworks: wifi ? wifi.networks.values.slice().sort((a, b) => b.signalStrength - a.signalStrength).slice(0, 8) : []
    property var ip: ({}) // nmcli device show <iface>: IP4.ADDRESS[1], IP4.GATEWAY, IP4.DNS[1]...

    function speed(mbps) {
        return mbps >= 1000 ? mbps / 1000 + "G" : mbps > 0 ? mbps + "M" : "";
    }

    code: "NW-03"

    onWiredChanged: details.running = !!wired
    Component.onCompleted: details.running = !!wired

    Process {
        id: details
        command: ["nmcli", "-t", "-f", "GENERAL.CONNECTION,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS", "device", "show", root.wired?.name ?? ""]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = {};
                for (const line of text.trim().split("\n")) {
                    const i = line.indexOf(":");
                    const key = line.slice(0, i).replace(/\[\d+\]/, "");
                    if (!out[key])
                        out[key] = line.slice(i + 1);
                    else
                        out[key] += ", " + line.slice(i + 1);
                }
                root.ip = out;
            }
        }
    }

    // lead (v2)
    Item {
        width: parent.width
        height: lead.height + 18
        CCHero {
            id: lead
            x: 22
            y: 18
            width: parent.width - 44
            size: 110
            value: root.wired?.connected ? "WIRED" : "OFFLINE"
            unit: ""
            sub: (root.wired ? "ETHERNET · " + root.wired.name.toUpperCase() : "NO WIRED DEVICE") + "  ·  " + root.devices.filter(d => d.connected).length + " UP  ·  NETWORKMANAGER"
        }
    }

    Column {
        x: 22
        width: parent.width - 44
        spacing: 0
        bottomPadding: 14

        // ---- wired: the connection as a spec sheet, two columns of key / value ----
        Grid {
            visible: !!root.wired
            width: parent.width
            columns: 2
            columnSpacing: 22
            Repeater {
                model: [
                    ["CONNECTION", root.ip["GENERAL.CONNECTION"] || root.wired?.name || "", ""],
                    ["IPV4", (root.ip["IP4.ADDRESS"] || "—").split("/")[0], root.ip["IP4.ADDRESS"]?.includes("/") ? "/" + root.ip["IP4.ADDRESS"].split("/")[1] : ""],
                    ["GATEWAY", root.ip["IP4.GATEWAY"] || "—", ""],
                    ["DNS", (root.ip["IP4.DNS"] || "—").split(",")[0], ""],
                    ["MAC", root.wired?.address || "—", ""],
                    ["LINK", root.wired?.connected ? String(root.wired.linkSpeed || "—") : root.wired?.hasLink ? "DOWN" : "NO CABLE", root.wired?.connected && root.wired.linkSpeed ? "MB/S" : ""]
                ]
                Item {
                    required property var modelData
                    width: (parent.width - 22) / 2
                    height: 62
                    Text {
                        y: 10
                        text: parent.modelData[0]
                        color: Theme.dim
                        font.family: Theme.mono
                        font.pixelSize: 10
                        font.letterSpacing: 2
                    }
                    Row {
                        y: 26
                        width: parent.width
                        spacing: 4
                        Text {
                            id: val
                            width: Math.min(implicitWidth, parent.width - unit.implicitWidth - 4)
                            elide: Text.ElideRight
                            text: parent.parent.modelData[1]
                            color: Theme.ink
                            font.family: GroundTheme.display
                            font.weight: Font.ExtraBold
                            font.variableAxes: { "wdth": 80, "wght": 800 }
                            font.pixelSize: 22
                        }
                        Text {
                            id: unit
                            anchors.baseline: val.baseline
                            text: parent.parent.modelData[2]
                            color: Theme.dim
                            font.family: GroundTheme.display
                            font.weight: Font.Bold
                            font.variableAxes: { "wght": 700 }
                            font.pixelSize: 13
                        }
                    }
                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: GroundTheme.line }
                }
            }
        }
        Item { width: 1; height: 14 }
        // connect / disconnect: orange outline
        Rectangle {
            visible: !!root.wired
            width: btn.implicitWidth + 30
            height: 36
            color: btnArea.containsMouse ? Qt.rgba(1, 95 / 255, 31 / 255, 0.12) : "transparent"
            border.width: 1
            border.color: GroundTheme.acc
            Text {
                id: btn
                anchors.centerIn: parent
                text: root.wired?.connected ? "DISCONNECT" : "CONNECT"
                color: GroundTheme.acc
                font.family: Theme.mono
                font.weight: Font.Bold
                font.pixelSize: 11
                font.letterSpacing: 2.2
            }
            MouseArea {
                id: btnArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.wired.connected ? root.wired.disconnect() : root.wired.network?.connect()
            }
        }
        Item { width: 1; height: 22 }

        // ---- wi-fi (only with a Wi-Fi device) ----
        Group { visible: !!root.wifi; text: "WI-FI · " + String(root.wifiNetworks.length).padStart(2, "0") }
        CCSwitch {
            visible: !!root.wifi
            label: "WI-FI"
            on: Networking.wifiEnabled
            onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
        }
        Column {
            width: parent.width
            visible: !!root.wifi && Networking.wifiEnabled
            Repeater {
                model: root.wifiNetworks
                DeviceRow {
                    required property var modelData
                    name: modelData.name
                    detail: Math.round(modelData.signalStrength * 100) + "% · " + (modelData.known ? "KNOWN" : "NEW")
                        + (modelData.security ? " · SECURED" : " · OPEN")
                    current: modelData.connected
                    tag: "CONNECTED"
                    // known or open networks only for now; typing a new password comes later
                    onClicked: if (!modelData.connected && (modelData.known || !modelData.security)) modelData.connect()
                }
            }
        }
        Item { visible: !!root.wifi; width: 1; height: 18 }

        // ---- vpn: switch rows ----
        Group { text: "VPN · " + String(Vpn.connections.length).padStart(2, "0") }
        Repeater {
            model: Vpn.connections
            CCSwitch {
                required property var modelData
                label: modelData.name.toUpperCase() + " · " + modelData.type.toUpperCase()
                on: modelData.active
                onClicked: Vpn.toggle(modelData.name)
            }
        }
        CCSwitch {
            visible: Vpn.connections.length === 0
            label: "NO VPN IN NETWORKMANAGER"
            available: false
        }
    }

    component Group: Text {
        bottomPadding: 4
        color: Theme.dim
        font.family: Theme.mono
        font.pixelSize: 10
        font.letterSpacing: 2.4
    }
}
