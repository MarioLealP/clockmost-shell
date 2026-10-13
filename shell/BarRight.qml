// .right: now playing, the status tray plate, the user chip.
import QtQuick

Row {
    spacing: 12

    NowPlaying {
        anchors.verticalCenter: parent.verticalCenter
    }
    StatusTray {
        anchors.verticalCenter: parent.verticalCenter
    }
    UserChip {
        anchors.verticalCenter: parent.verticalCenter
    }
}
