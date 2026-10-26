// The user square (v2): an orange plate with the initial; click = the control center (as the old chip did via the bar).
import QtQuick
import Quickshell

Rectangle {
    id: root

    readonly property string user: (Quickshell.env("USER") || "user").toUpperCase()

    width: 52
    height: 52
    color: GroundTheme.acc

    Text {
        anchors.centerIn: parent
        text: root.user.slice(0, 1)
        color: GroundTheme.accInk
        font.family: GroundTheme.display
        font.weight: Font.Black
        font.variableAxes: { "wght": 900 }
        font.pixelSize: 24
    }
}
