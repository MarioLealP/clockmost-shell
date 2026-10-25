// ds-dock-v2 .tip: hover label above a slot - padding 7/10/6, rgba(12,13,15,.94), 1px rgba(255,255,255,.16) border,
// 3px violet left bar; b = 700 11px mono .2em; span = 8px mono .18em dim; a rotated 10px square as the pointer.
import QtQuick

Item {
    id: root

    property string title
    property string sub

    implicitWidth: col.implicitWidth + 20
    implicitHeight: col.implicitHeight + 13

    // pointer: 10x10 turned 45deg, right + bottom borders only, centred under the plate (CSS bottom -6px)
    Item {
        x: root.width / 2 - 5
        y: root.height - 4
        width: 10
        height: 10
        rotation: 45
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(12 / 255, 13 / 255, 15 / 255, 0.94)
        }
        Rectangle {
            anchors.right: parent.right
            width: 1
            height: parent.height
            color: Qt.rgba(1, 1, 1, 0.16)
        }
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: Qt.rgba(1, 1, 1, 0.16)
        }
    }
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(12 / 255, 13 / 255, 15 / 255, 0.94)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.16)
    }
    Rectangle {
        width: 3
        height: parent.height
        color: GroundTheme.acc // v2
    }
    Column {
        id: col
        x: 10
        y: 7
        Text {
            text: root.title.toUpperCase()
            color: Theme.ink
            font.family: Theme.mono
            font.weight: Font.Bold
            font.pixelSize: 11
            font.letterSpacing: Theme.em(11, 0.2)
        }
        Text {
            text: root.sub.toUpperCase()
            color: Theme.dim
            font.family: Theme.mono
            font.pixelSize: 8
            font.letterSpacing: Theme.em(8, 0.18)
        }
    }
}
