// The app tray (StatusNotifier icons: KeePassXC, Steam, Discord, Spotify...): a plate like the status tray, left of
// it; hidden while no app has an icon. Left = activate (or the menu, for menu-only items), right = the app's menu
// (Quit lives there), middle = secondary activate, wheel = scroll. Mario 2026-10-14: "keepass is basically unusable".
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Rectangle {
    id: root

    visible: SystemTray.items.values.length > 0
    implicitWidth: visible ? row.implicitWidth + 12 : 0
    implicitHeight: 38
    color: Qt.rgba(12 / 255, 13 / 255, 15 / 255, 0.7)
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.10)

    // corner brackets: top-left and bottom-right, 10px, 2px (as the status tray)
    Repeater {
        model: [{ x: -1, y: -1, r: 0 }, { x: root.width - 9, y: root.height - 9, r: 180 }]
        Item {
            required property var modelData
            x: modelData.x
            y: modelData.y
            width: 10
            height: 10
            rotation: modelData.r
            Rectangle { width: 10; height: 2; color: Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.4) }
            Rectangle { width: 2; height: 10; color: Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.4) }
        }
    }

    Row {
        id: row
        x: 6
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: SystemTray.items
            AppTrayIcon {}
        }
    }
}
