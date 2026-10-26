// .right: the app tray (hidden while empty), the status tray plate (v2: no user chip - Mario 2026-10-26). Now playing: left of the clock (Bar).
import QtQuick

Row {
    spacing: 6

    AppTray {
        anchors.verticalCenter: parent.verticalCenter
    }
    StatusTray {
        anchors.verticalCenter: parent.verticalCenter
    }
}
