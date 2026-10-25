// ds-dock-v2 .div: 1x44 rgba(255,255,255,.10), margin 0 2px.
import QtQuick

Item {
    width: 5
    height: 44
    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    anchors.verticalCenterOffset: -4 // on the tiles' centre line (slots carry 8px of marks below)
    Rectangle {
        x: 2
        width: 1
        height: parent.height
        color: Qt.rgba(0.1, 0.1, 0.09, 0.3) // v2: dark on the bone plate
    }
}
