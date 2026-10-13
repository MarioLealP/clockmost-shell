// Popup stack: top-right under the bar (the mock: right 16, top 62), newest first, max 4. Only the cards take
// input; the rest of the window lets clicks through.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    readonly property real s: Math.min(1, screen ? screen.width / 1920 : 1)

    visible: Notifs.popups.length > 0 && !ControlCenter.open
    anchors {
        top: true
        right: true
    }
    margins.top: 62 * s
    margins.right: 16 * s
    implicitWidth: 400 * s + 8
    implicitHeight: Math.max(1, stack.height * s + 8)
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "clockmost-notifications"
    WlrLayershell.layer: WlrLayer.Overlay

    mask: Region {
        item: stack
    }

    Column {
        id: stack
        x: 2
        y: 2
        scale: root.s
        transformOrigin: Item.TopLeft
        spacing: 10
        Repeater {
            model: Notifs.popups
            NotifCard {
                required property var modelData
                rec: modelData
            }
        }
    }
}
