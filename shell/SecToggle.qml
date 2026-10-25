// A click-to-toggle chip bound to one HA entity (● on / ○ off).
import QtQuick

Rectangle {
    id: root

    property string entity
    property string label
    readonly property bool on: HaClient.isOn(entity)

    width: t.implicitWidth + 26
    height: 36
    color: on ? GroundTheme.ink : (ma.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : GroundTheme.bg)
    border.width: 1.5
    border.color: on ? GroundTheme.ink : GroundTheme.line

    Text {
        id: t
        anchors.centerIn: parent
        text: (root.on ? "●  " : "○  ") + root.label
        color: root.on ? GroundTheme.bg : GroundTheme.ink2
        font.family: GroundTheme.mono
        font.pixelSize: 11
        font.letterSpacing: 2
    }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: HaClient.toggle(root.entity) }
}
