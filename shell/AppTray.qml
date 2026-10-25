// The app tray (StatusNotifier icons: KeePassXC, Steam, Discord, Spotify...): a plate like the status tray, left of
// it; hidden while no app has an icon. Left = activate (or the menu, for menu-only items), right = the app's menu
// (Quit lives there), middle = secondary activate, wheel = scroll. Mario 2026-10-14: "keepass is basically unusable".
import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

Rectangle {
    id: root

    visible: SystemTray.items.values.length > 0
    implicitWidth: visible ? row.implicitWidth + 16 : 0
    implicitHeight: 52
    color: GroundTheme.ink // v2: a bone plate


    Row {
        id: row
        x: 8
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: SystemTray.items
            AppTrayIcon {}
        }
    }
}
