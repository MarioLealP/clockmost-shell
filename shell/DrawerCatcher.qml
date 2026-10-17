// The app drawer's outside-click catcher for the screens the drawer isn't on: a click anywhere closes it. The bar
// and dock strips are left out (they close it themselves, via DrawerCloser, and keep working).
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    visible: Drawer.open
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "clockmost-drawer-catcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    mask: Region {
        item: catcher
        Region {
            intersection: Intersection.Subtract
            width: root.width
            height: Drawer.topInset(root.width)
        }
        Region {
            intersection: Intersection.Subtract
            y: root.height - Drawer.bottomInset(root.width)
            width: root.width
            height: Drawer.bottomInset(root.width)
        }
    }

    MouseArea {
        id: catcher
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: Drawer.close()
    }
}
