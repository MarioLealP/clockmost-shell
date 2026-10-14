// One app-tray item: the app's own icon (18px) on a 36x36 tile, with the status tray's 2px underline (orange =
// the app wants attention).
import QtQuick
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
        const p = root.mapToItem(null, 0, root.height);
        root.modelData.display(QsWindow.window, Math.round(p.x), Math.round(p.y));
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(1, 1, 1, area.containsMouse ? 0.06 : 0)
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    IconImage {
        anchors.centerIn: parent
        implicitSize: 18
        source: root.modelData.icon
        opacity: area.containsMouse ? 1 : 0.85
    }

    Rectangle {
        x: 11
        width: parent.width - 22
        y: parent.height - 4 - 2
        height: 2
        color: root.attention ? Theme.orange : Theme.ink2
        opacity: root.attention ? 1 : 0.35
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
                root.modelData.activate();
            }
        }
        onWheel: wheel => root.modelData.scroll(wheel.angleDelta.y / 120, false)
    }
}
