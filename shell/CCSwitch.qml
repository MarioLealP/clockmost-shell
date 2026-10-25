// A switch row (v2): LABEL ............ ● ON (orange) / ○ OFF. Click = toggle; disabled rows read dim.
import QtQuick

Item {
    id: root

    property string label
    property string state: "" // overrides ON/OFF (e.g. "SOON", "NOT SET UP")
    property bool on: false
    property bool available: true
    signal clicked

    width: parent ? parent.width : 0
    height: 34

    Rectangle { anchors.fill: parent; color: area.containsMouse && root.available ? Qt.rgba(1, 1, 1, 0.04) : "transparent" }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: root.available ? Theme.ink : Theme.dim
        font.family: Theme.mono
        font.pixelSize: 12
        font.letterSpacing: 2
    }
    Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: (root.on ? "●  " : "○  ") + (root.state !== "" ? root.state : root.on ? "ON" : "OFF")
        color: root.on ? GroundTheme.acc : Theme.dim
        font.family: Theme.mono
        font.pixelSize: 11
        font.letterSpacing: 2
    }
    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: GroundTheme.line }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.available
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
