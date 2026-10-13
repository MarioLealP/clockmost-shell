// .ti: a 36x36 status icon (18px glyph) with a 2px colour underline (left/right 11, bottom 4, .85).
import QtQuick

Item {
    id: root

    property string path: ""
    property color accent: Theme.ink2
    property bool attention: false
    property bool open: false // its control-center tab is showing
    signal clicked
    signal middleClicked

    width: 36
    height: 36

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(1, 1, 1, area.containsMouse ? 0.06 : 0)
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    Item {
        anchors.centerIn: parent
        width: 18
        height: 18
        Glyph {
            path: root.path
            color: root.open ? Theme.yellow : area.containsMouse ? Theme.ink : Theme.ink2
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
        color: root.accent
        opacity: 0.85
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: mouse => mouse.button === Qt.MiddleButton ? root.middleClicked() : root.clicked()
    }
}
