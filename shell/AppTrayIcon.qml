// One app-tray item: the app's own icon (18px) on a 36x36 tile, with the status tray's 2px underline (orange =
// the app wants attention). Tooltip = the app's name (500ms hover); right click = TrayMenu (TrayMenuWindow).
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Item {
    id: root

    required property SystemTrayItem modelData
    readonly property bool attention: modelData.status === Status.NeedsAttention

    width: 36
    height: 36

    function showMenu() {
        // the Endfield tray menu (TrayMenuWindow), centred under this icon on this screen
        const win = QsWindow.window;
        const x = root.mapToItem(null, root.width / 2, 0).x;
        TrayMenu.show(root.modelData, win?.screen?.name ?? "", x);
    }

    Rectangle {
        anchors.fill: parent
        color: area.containsMouse ? Qt.rgba(0, 0, 0, 0.08) : "transparent"
    }

    IconImage {
        anchors.centerIn: parent
        implicitSize: 18
        source: root.modelData.icon
        // v2: every tray icon in the plate's dark ink (white symbolic icons would vanish on bone)
        layer.enabled: true
        layer.effect: MultiEffect {
            colorization: 1.0
            colorizationColor: GroundTheme.bg
        }
    }

    Rectangle {
        x: 11
        width: parent.width - 22
        y: parent.height - 4 - 2
        height: 2
        visible: root.attention
        color: GroundTheme.acc
    }

    Timer {
        id: tipDelay
        interval: 500
        running: area.containsMouse && !TrayMenu.open
    }
    PopupWindow {
        visible: area.containsMouse && !tipDelay.running && !TrayMenu.open && tip.text !== ""
        anchor.item: root
        anchor.rect.x: root.width / 2 - implicitWidth / 2
        anchor.rect.y: root.height + 6
        implicitWidth: tip.implicitWidth + 16
        implicitHeight: 22
        color: "transparent"
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(16 / 255, 17 / 255, 20 / 255, 0.95)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.12)
            Text {
                id: tip
                anchors.centerIn: parent
                text: (root.modelData.tooltipTitle || root.modelData.title || root.modelData.id).toUpperCase()
                color: Theme.ink2
                font.family: Theme.mono
                font.pixelSize: 10
                font.letterSpacing: Theme.em(10, 0.14)
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton || (mouse.button === Qt.LeftButton && root.modelData.onlyMenu)) {
                if (root.modelData.hasMenu)
                    root.showMenu();
            } else if (mouse.button === Qt.MiddleButton) {
                root.modelData.secondaryActivate();
            } else {
                root.modelData.activate(QsWindow.window); // hands it a wayland activation token (patched quickshell)
            }
        }
        onWheel: wheel => root.modelData.scroll(wheel.angleDelta.y / 120, false)
    }
}
