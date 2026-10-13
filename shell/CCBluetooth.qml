// Control center BLUETOOTH tab (BlueZ via Quickshell.Bluetooth): adapter switch, paired devices with battery and
// connect/disconnect, a scan for new devices to pair. No mock of its own - built from the panel parts.
import QtQuick
import Quickshell.Bluetooth

CCTab {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var all: adapter ? adapter.devices.values : []
    readonly property var paired: all.filter(d => d.paired || d.bonded).sort((a, b) => b.connected - a.connected)
    readonly property var found: all.filter(d => !d.paired && !d.bonded && (d.name || d.deviceName))

    function title(d) {
        return d.name || d.deviceName || d.address;
    }

    code: "BT-04"

    // stop scanning when the tab goes away
    Component.onDestruction: if (adapter && adapter.discovering) adapter.discovering = false

    CCHeader {
        title: "BLUETOOTH"
        sub: root.adapter ? (root.adapter.name || root.adapter.adapterId).toUpperCase() + " · BLUEZ" : "NO ADAPTER · BLUEZ NOT RUNNING"
        count: String(root.paired.filter(d => d.connected).length)
        countLabel: "LINKED"
    }

    Column {
        x: 18
        width: parent.width - 36
        spacing: 10
        bottomPadding: 14

        Micro {
            visible: !root.adapter
            text: "NO BLUETOOTH ADAPTER FOUND"
        }

        // adapter on/off
        Item {
            visible: !!root.adapter
            width: parent.width
            height: 14
            SectionLabel { text: "ADAPTER"; width: parent.width - 50 }
            Switch {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                on: root.adapter?.enabled ?? false
                onToggled: root.adapter.enabled = !root.adapter.enabled
            }
        }

        // ---- paired ----
        SectionLabel {
            visible: root.adapter?.enabled ?? false
            text: "PAIRED"
            note: String(root.paired.length).padStart(2, "0")
        }
        Column {
            width: parent.width
            visible: root.adapter?.enabled ?? false
            Repeater {
                model: root.paired
                Item {
                    id: dev
                    required property var modelData
                    width: parent.width
                    height: 44
                    Rectangle {
                        anchors.fill: parent
                        color: Qt.rgba(1, 1, 1, dev.modelData.connected ? 0.06 : devArea.containsMouse ? 0.035 : 0)
                        Behavior on color { ColorAnimation { duration: 140 } }
                    }
                    Rectangle {
                        width: 3
                        height: parent.height
                        color: "#5aa7ff"
                        visible: dev.modelData.connected
                    }
                    Row {
                        x: 14
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12
                        Glyph {
                            anchors.verticalCenter: parent.verticalCenter
                            path: Icons.device(dev.modelData.icon)
                            color: dev.modelData.connected ? "#5aa7ff" : Theme.dim
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3
                            Text {
                                text: root.title(dev.modelData)
                                color: dev.modelData.connected ? Theme.ink : Theme.ink2
                                font.family: Theme.body
                                font.pixelSize: 13
                            }
                            Micro {
                                text: (dev.modelData.state === BluetoothDeviceState.Connecting ? "CONNECTING…"
                                    : dev.modelData.state === BluetoothDeviceState.Disconnecting ? "DISCONNECTING…"
                                    : dev.modelData.connected ? "CONNECTED" : "PAIRED")
                                    + (dev.modelData.batteryAvailable ? " · " + Math.round(dev.modelData.battery * 100) + "%" : "")
                            }
                        }
                    }
                    // battery bar (when the device reports one)
                    Rectangle {
                        visible: dev.modelData.batteryAvailable
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: 34
                        height: 10
                        color: "transparent"
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.2)
                        Rectangle {
                            x: 2
                            y: 2
                            height: parent.height - 4
                            width: (parent.width - 4) * Math.max(0, Math.min(1, dev.modelData.battery))
                            color: dev.modelData.battery < 0.2 ? Theme.crimson : Theme.green
                        }
                    }
                    MouseArea {
                        id: devArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: dev.modelData.connected ? dev.modelData.disconnect() : dev.modelData.connect()
                    }
                }
            }
        }
        Micro {
            visible: (root.adapter?.enabled ?? false) && root.paired.length === 0
            text: "NOTHING PAIRED YET"
        }

        // ---- scan / pair ----
        Item {
            visible: root.adapter?.enabled ?? false
            width: parent.width
            height: 22
            SectionLabel {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - scanBtn.width - 10
                text: "NEARBY"
                note: root.adapter?.discovering ? String(root.found.length).padStart(2, "0") : ""
            }
            Rectangle {
                id: scanBtn
                anchors.right: parent.right
                width: scanText.implicitWidth + 16
                height: 22
                color: root.adapter?.discovering ? Qt.rgba(1, 250 / 255, 0, 0.34) : scanArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                border.width: 1
                border.color: root.adapter?.discovering ? Qt.rgba(1, 250 / 255, 0, 0.45) : Qt.rgba(1, 1, 1, 0.16)
                Text {
                    id: scanText
                    anchors.centerIn: parent
                    text: root.adapter?.discovering ? "SCANNING" : "SCAN"
                    color: root.adapter?.discovering ? "#fffbb0" : Theme.ink2
                    font.family: Theme.mono
                    font.weight: Font.Bold
                    font.pixelSize: 9
                    font.letterSpacing: Theme.em(9, 0.18)
                    SequentialAnimation on opacity {
                        running: root.adapter?.discovering ?? false
                        loops: Animation.Infinite
                        onStopped: scanText.opacity = 1
                        NumberAnimation { to: 0.4; duration: 600 }
                        NumberAnimation { to: 1; duration: 600 }
                    }
                }
                MouseArea {
                    id: scanArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.adapter.discovering = !root.adapter.discovering
                }
            }
        }
        Column {
            width: parent.width
            visible: (root.adapter?.discovering ?? false) && root.found.length > 0
            Repeater {
                model: root.found
                DeviceRow {
                    required property var modelData
                    name: root.title(modelData)
                    detail: modelData.pairing ? "PAIRING…" : "CLICK TO PAIR · " + modelData.address
                    current: modelData.pairing
                    tag: "PAIRING"
                    onClicked: if (!modelData.pairing) modelData.pair()
                }
            }
        }
    }
}
