// .tray: one grouped plate - weather readout, status icons, notifications - with corner brackets.
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Rectangle {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink?.audio?.muted ?? false

    function cc(tab, cx) {
        ControlCenter.toggle(tab, QsWindow.window?.screen?.name ?? "", cx);
    }
    function isOpen(tab) {
        return ControlCenter.open && ControlCenter.tab === tab;
    }

    implicitWidth: row.implicitWidth + 12
    implicitHeight: 38
    color: Qt.rgba(12 / 255, 13 / 255, 15 / 255, 0.7)
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.10)

    PwObjectTracker {
        objects: [root.sink]
    }

    // corner brackets: top-left and bottom-right, 10px, 2px
    Repeater {
        model: [{ x: -1, y: -1, r: 0 }, { x: root.width - 9, y: root.height - 9, r: 180 }]
        Item {
            required property var modelData
            x: modelData.x
            y: modelData.y
            width: 10
            height: 10
            rotation: modelData.r
            Rectangle { width: 10; height: 2; color: Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.4) }
            Rectangle { width: 2; height: 10; color: Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.4) }
        }
    }

    Row {
        id: row
        x: 6
        anchors.verticalCenter: parent.verticalCenter

        // weather: yellow glyph + temperature / CITY · CONDITION
        Row {
            anchors.verticalCenter: parent.verticalCenter
            leftPadding: 8
            spacing: 2
            Glyph {
                anchors.verticalCenter: parent.verticalCenter
                path: Icons.weather(Weather.icon)
                color: Theme.yellow
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                leftPadding: 8
                rightPadding: 8
                spacing: 3
                Text {
                    text: Weather.ready ? Weather.temperature + "°C" : "--°C"
                    color: Theme.ink
                    font.family: Theme.mono
                    font.weight: Font.Bold
                    font.pixelSize: 12
                    font.letterSpacing: Theme.em(12, 0.12)
                }
                Text {
                    width: Math.min(implicitWidth, 120) // mock: "LISBON · CLEAR"; long place names elide
                    elide: Text.ElideRight
                    text: Weather.ready ? Weather.city + " · " + Weather.condition : "LOCATING"
                    color: Theme.faint
                    font.family: Theme.mono
                    font.pixelSize: 8
                    font.letterSpacing: Theme.em(8, 0.18)
                }
            }
        }

        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 9; height: 18; color: "transparent"
            Rectangle { anchors.centerIn: parent; width: 1; height: 18; color: Qt.rgba(1, 1, 1, 0.10) } }

        TrayIcon { path: Icons.clipboard; accent: Theme.magenta; open: root.isOpen("clipboard"); onClicked: cx => root.cc("clipboard", cx) }
        TrayIcon {
            path: root.muted ? Icons.volumeMuted : Icons.volume
            accent: root.muted ? Theme.faint : Theme.cyan
            open: root.isOpen("home")
            onClicked: cx => root.cc("home", cx) // the mock: volume icon = quick settings
            onMiddleClicked: if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted
        }
        TrayIcon { path: Icons.bluetooth; accent: "#5aa7ff"; open: root.isOpen("bluetooth"); onClicked: cx => root.cc("bluetooth", cx) }
        TrayIcon { path: Icons.vpn; accent: Theme.green; open: root.isOpen("network"); onClicked: cx => root.cc("network", cx) }

        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: 9; height: 18; color: "transparent"
            Rectangle { anchors.centerIn: parent; width: 1; height: 18; color: Qt.rgba(1, 1, 1, 0.10) } }

        TrayIcon {
            path: Notifs.dnd ? Icons.dnd : Icons.bell
            accent: Theme.orange
            attention: Notifs.unread > 0 // the orange diamond
            open: root.isOpen("notifications")
            onClicked: cx => root.cc("notifications", cx)
        }
    }
}
