// The dock's right-click menu, Windows taskbar style: the app's own desktop actions (its jump list), then open a new
// window, pin / unpin, close the window(s). Same overlay and material as the tray menu (TrayMenuWindow): click
// outside or Esc = close, fade + 12px slide, 180ms OutCubic; the panel sits above the slot, kept on screen.
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    readonly property real s: Math.min(1, width / 1920)
    property real openP: DockMenu.open ? 1 : 0
    Behavior on openP { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    readonly property bool mine: DockMenu.screenName === "" || DockMenu.screenName === screen?.name
    visible: mine && (DockMenu.open || openP > 0.001)
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "clockmost-dockmenu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: DockMenu.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: Region {
        item: DockMenu.open ? catcher : null
    }

    // the rows for the open slot: {label, run} or {separator: true}
    readonly property var rows: {
        const sl = DockMenu.slot;
        if (!sl)
            return [];
        const out = [];
        const actions = sl.entry?.actions ?? [];
        for (const a of actions)
            out.push({ label: a.name, run: () => a.execute() });
        if (actions.length)
            out.push({ separator: true });
        if (sl.entry)
            out.push({ label: sl.windows.length ? "Open new window" : "Open", run: () => DockApps.launch(sl) });
        if (sl.entry)
            out.push({
                label: DockApps.isPinned(sl.key) ? "Unpin from dock" : "Pin to dock",
                run: () => DockApps.togglePin(sl.key)
            });
        if (sl.windows.length)
            out.push({
                label: sl.windows.length === 1 ? "Close window" : "Close all windows (" + sl.windows.length + ")",
                run: () => DockApps.closeAll(sl)
            });
        return out;
    }

    MouseArea {
        id: catcher
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: DockMenu.close()
    }

    Item {
        anchors.fill: parent
        focus: DockMenu.open
        Keys.onEscapePressed: DockMenu.close()
    }

    Item {
        id: scaled
        width: root.width / root.s
        height: root.height / root.s
        scale: root.s
        transformOrigin: Item.TopLeft

        Item {
            id: panel
            width: Math.max(220, list.implicitWidth + 24)
            height: list.implicitHeight + 26
            x: {
                const maxX = scaled.width - width - 16;
                return DockMenu.anchorX < 0 ? (scaled.width - width) / 2
                    : Math.max(16, Math.min(maxX, DockMenu.anchorX / root.s - width / 2));
            }
            // above the dock plate (14px off the bottom, 84px tall) with the preview's 20px gap
            y: scaled.height - 14 - 84 - 20 - height + 12 * (1 - root.openP)
            opacity: root.openP

            // clicks on the panel stay on the panel
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
            }

            RectangularShadow {
                anchors.fill: parent
                offset.y: 20
                blur: 60
                radius: 2
                color: Qt.rgba(0, 0, 0, 0.45)
            }
            DockPlate {
                anchors.fill: parent
            }

            Column {
                id: list
                x: 12
                y: 14 // clears the plate's 7px ruler
                width: panel.width - 24

                // head: APP NAME - rule (the dock preview's .gl)
                Row {
                    width: parent.width
                    spacing: 8
                    bottomPadding: 6
                    Text {
                        id: head
                        text: (DockMenu.slot?.name ?? "").toUpperCase()
                        color: GroundTheme.bg // v2: dark on the bone plate
                        font.family: Theme.mono
                        font.weight: Font.Bold
                        font.pixelSize: 12
                        font.letterSpacing: Theme.em(12, 0.14)
                        elide: Text.ElideRight
                        width: Math.min(implicitWidth, list.width - 40)
                    }
                    Rectangle {
                        anchors.verticalCenter: head.verticalCenter
                        width: Math.max(0, list.width - head.width - 8)
                        height: 1
                        color: Qt.rgba(0.1, 0.1, 0.09, 0.25)
                    }
                }

                Repeater {
                    model: root.rows
                    TrayMenuRow {
                        required property var modelData
                        width: list.width
                        separator: modelData.separator ?? false
                        label: modelData.label ?? ""
                        onActivated: {
                            DockMenu.close();
                            modelData.run();
                        }
                    }
                }
            }
        }
    }
}
