// .right: the app tray (hidden while empty), the status tray plate, the user chip. Now playing: left of the clock (Bar).
import QtQuick

Row {
    spacing: 6

    AppTray {
        anchors.verticalCenter: parent.verticalCenter
    }
    StatusTray {
        anchors.verticalCenter: parent.verticalCenter
    }
    UserChip {
        anchors.verticalCenter: parent.verticalCenter
    }
}
