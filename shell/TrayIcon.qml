// .ti: a 36x36 status icon (18px glyph) with a 2px colour underline (left/right 11, bottom 4, .85).
import QtQuick

Item {
    id: root

    property string path: ""
    property color accent: Theme.ink2
    property bool attention: false
    property bool open: false // its control-center tab is showing
    signal clicked(real cx)
    signal middleClicked

    width: 36
    height: 36

    Rectangle {
        anchors.fill: parent
        color: area.containsMouse ? Qt.rgba(0, 0, 0, 0.08) : "transparent"
    }

    Item {
        anchors.centerIn: parent
        width: 18
        height: 18
        Glyph {
            path: root.path
            color: root.open ? GroundTheme.acc : GroundTheme.bg
        }
        AttentionPin {
            visible: root.attention
        }
    }

    Rectangle {
        x: 11
        width: parent.width - 22
        y: parent.height - 4 - 2
        height: 2
        visible: root.open // v2: no colour underlines - only the open tab gets an orange one
        color: GroundTheme.acc
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => mouse.button === Qt.MiddleButton ? root.middleClicked() : root.clicked(root.mapToItem(null, root.width / 2, 0).x)
    }
}
