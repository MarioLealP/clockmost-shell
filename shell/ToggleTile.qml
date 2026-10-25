// A quick-settings toggle (v2): orange = on, hairline = off.
import QtQuick

Item {
    id: root

    property string icon: ""
    property string title: ""
    property string status: ""
    property string index: ""
    property color accent: Theme.ink2
    property bool on: false
    property bool available: true
    signal clicked

    implicitHeight: 62

    // v2: flat - on = orange fill + dark ink, off = a hairline outline
    Rectangle {
        anchors.fill: parent
        color: root.on ? GroundTheme.acc : (area.containsMouse && root.available ? Qt.rgba(1, 1, 1, 0.05) : "transparent")
        border.width: root.on ? 0 : 1
        border.color: GroundTheme.line
    }
    Row {
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10
        Glyph {
            anchors.verticalCenter: parent.verticalCenter
            size: 20
            path: root.icon
            color: root.on ? GroundTheme.accInk : Theme.dim
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            Text {
                text: root.title
                color: root.on ? GroundTheme.accInk : Theme.ink
                font.family: Theme.mono
                font.weight: Font.Bold
                font.pixelSize: 11
                font.letterSpacing: 2
            }
            Text {
                text: root.status
                color: root.on ? Qt.rgba(0.07, 0.07, 0.06, 0.7) : Theme.dim
                font.family: Theme.mono
                font.pixelSize: 9
                font.letterSpacing: 2
            }
        }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.available
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
