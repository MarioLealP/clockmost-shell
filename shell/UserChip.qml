// .user: notched initials avatar + NAME / ● ONLINE.
import QtQuick
import QtQuick.Shapes
import Quickshell

Row {
    id: root

    readonly property string user: (Quickshell.env("USER") || "user").toUpperCase()

    spacing: 8

    Item {
        anchors.verticalCenter: parent.verticalCenter
        width: 34
        height: 34
        // clip-path: polygon(0 0, 100%-8 0, 100% 8, 100% 100%, 8 100%, 0 100%-8)
        Shape {
            anchors.fill: parent
            ShapePath {
                strokeWidth: 0
                fillColor: Theme.ink
                PathSvg { path: "M0 0H26L34 8V34H8L0 26z" }
            }
        }
        Text {
            anchors.centerIn: parent
            text: root.user.slice(0, 2)
            color: Theme.plateInk
            font.family: Theme.mono
            font.weight: Font.Bold
            font.pixelSize: 11
            font.letterSpacing: Theme.em(11, 0.1)
        }
    }

    Column {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3
        Text {
            text: root.user
            color: Theme.ink
            font.family: Theme.mono
            font.weight: Font.Bold
            font.pixelSize: 11
            font.letterSpacing: Theme.em(11, 0.2)
        }
        Text {
            text: "● ONLINE"
            color: Theme.green
            font.family: Theme.mono
            font.pixelSize: 8
            font.letterSpacing: Theme.em(8, 0.18)
        }
    }
}
