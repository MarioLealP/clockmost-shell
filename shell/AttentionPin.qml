// .notif.pin: the orange 7px diamond with an offset outline, pinned to a host's top-right corner.
import QtQuick

Item {
    width: 7
    height: 7
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.topMargin: -3
    anchors.rightMargin: -3
    z: 2

    Rectangle {
        anchors.centerIn: parent
        width: 7 + 2 * 2.5 // outline-offset 1.5 + 1px outline
        height: width
        rotation: 45
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(1, 138 / 255, 31 / 255, 0.75)
    }
    Rectangle {
        anchors.fill: parent
        rotation: 45
        color: "#ff8a1f"
    }
}
