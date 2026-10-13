// ds-dock-v2 .div: 1x44 rgba(255,255,255,.10), margin 0 2px.
import QtQuick

Item {
    width: 5
    height: 44
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    Rectangle {
        x: 2
        width: 1
        height: parent.height
        color: Qt.rgba(1, 1, 1, 0.10)
    }
}
