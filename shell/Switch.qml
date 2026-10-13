// Square on/off switch in the house style: steel track, olive + yellow knob when on.
import QtQuick

Rectangle {
    id: root

    property bool on: false
    signal toggled

    width: 34
    height: 16
    color: on ? Qt.rgba(1, 250 / 255, 0, 0.34) : Qt.rgba(51 / 255, 54 / 255, 60 / 255, 0.6)
    border.width: 1
    border.color: on ? Qt.rgba(1, 250 / 255, 0, 0.45) : Qt.rgba(1, 1, 1, 0.10)
    Behavior on color { ColorAnimation { duration: 140 } }

    Rectangle {
        y: 3
        x: root.on ? root.width - width - 3 : 3
        width: 10
        height: 10
        color: root.on ? Theme.yellow : Theme.dim
        Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }
    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
