// Control center NETWORK tab: wired connection details (from NetworkManager), Wi-Fi when a Wi-Fi device exists,
// and every VPN with a switch. No mock of its own - built from the panel parts.
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
        spacing: 10
        bottomPadding: 14

        // ---- wired ----
        SectionLabel { text: "WIRED"; note: String(root.wiredDevices.length).padStart(2, "0") }
        Repeater {
            model: root.wiredDevices
            Rectangle {
                id: card
                required property var modelData
                width: parent.width
                height: col.implicitHeight + 24
                color: Qt.rgba(51 / 255, 54 / 255, 60 / 255, 0.35)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.07)
                Column {
                    id: col
                    x: 12
                    y: 12
                    width: parent.width - 24
                    spacing: 10
                    Row {
                        spacing: 12
                        Rectangle {
                            width: 26
                            height: 26
                            color: card.modelData.connected ? Theme.cyan : Qt.rgba(1, 1, 1, 0.08)
                            Glyph {
                                anchors.centerIn: parent
                                size: 16
                                path: Icons.ethernet
                                color: card.modelData.connected ? Theme.plateInk : Theme.dim
                            }
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3
                            Text {
                                text: (card.modelData === root.wired && root.ip["GENERAL.CONNECTION"]) || card.modelData.network?.name || card.modelData.name
                                color: Theme.ink
                                font.family: Theme.body
                                font.weight: Font.DemiBold
                                font.pixelSize: 13
                            }
                            Micro {
                                text: card.modelData.name + " · " + (card.modelData.connected
                                    ? "CONNECTED" + (root.speed(card.modelData.linkSpeed) ? " · " + root.speed(card.modelData.linkSpeed) : "")
                                    : card.modelData.hasLink ? "CABLE IN · DOWN" : "NO CABLE")
                            }
                        }
                    }
                    // details: label / value pairs
                    Grid {
                        visible: card.modelData === root.wired && card.modelData.connected
                        columns: 2
                        columnSpacing: 14
                        rowSpacing: 6
                        Repeater {
                            model: [["IPV4", root.ip["IP4.ADDRESS"]], ["GATEWAY", root.ip["IP4.GATEWAY"]], ["DNS", root.ip["IP4.DNS"]], ["MAC", card.modelData.address]]
                            Repeater {
                                required property var modelData
                                model: modelData[1] ? [modelData[0], modelData[1]] : []
                                Text {
                                    required property string modelData
                                    required property int index
                                    text: modelData
                                    color: index === 0 ? Theme.faint : Theme.ink2
                                    font.family: Theme.mono
                                    font.pixelSize: index === 0 ? 9 : 11
                                    font.letterSpacing: index === 0 ? Theme.em(9, 0.18) : 0.3
                                }
                            }
                        }
                    }
                }
                // connect / disconnect
                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    y: 12
                    width: btn.implicitWidth + 16
                    height: 22
                    color: btnArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.16)
                    Text {
                        id: btn
                        anchors.centerIn: parent
                        text: card.modelData.connected ? "DISCONNECT" : "CONNECT"
                        color: Theme.ink2
                        font.family: Theme.mono
                        font.weight: Font.Bold
                        font.pixelSize: 9
                        font.letterSpacing: Theme.em(9, 0.18)
                    }
                    MouseArea {
                        id: btnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: card.modelData.connected ? card.modelData.disconnect() : card.modelData.network?.connect()
                    }
                }
            }
        }
        Micro {
            visible: root.wiredDevices.length === 0
            text: "NO WIRED DEVICE"
        }

        // ---- wi-fi (only with a Wi-Fi device) ----
        Item {
            width: parent.width
            height: wifiHead.implicitHeight
            visible: !!root.wifi
            SectionLabel { id: wifiHead; text: "WI-FI"; width: parent.width - 50 }
            Switch {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                on: Networking.wifiEnabled
                onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
            }
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

        // ---- vpn ----
        SectionLabel { text: "VPN"; note: String(Vpn.connections.length).padStart(2, "0") }
        Repeater {
            model: Vpn.connections
            Item {
                id: vpnRow
                required property var modelData
                width: parent.width
                height: 40
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(1, 1, 1, vpnRow.modelData.active ? 0.06 : 0)
                }
                Rectangle {
                    width: 3
                    height: parent.height
                    color: Theme.green
                    visible: vpnRow.modelData.active
                }
                Column {
                    x: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3
                    Text {
                        text: vpnRow.modelData.name
                        color: vpnRow.modelData.active ? Theme.ink : Theme.ink2
                        font.family: Theme.body
                        font.pixelSize: 13
                    }
                    Micro {
                        text: vpnRow.modelData.type.toUpperCase() + " · " + (vpnRow.modelData.active ? "UP" : "DOWN")
                    }
                }
                Switch {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    on: vpnRow.modelData.active
                    onToggled: Vpn.toggle(vpnRow.modelData.name)
                }
            }
        }
        Micro {
            visible: Vpn.connections.length === 0
            text: "NO VPN IN NETWORKMANAGER"
        }
    }
}
