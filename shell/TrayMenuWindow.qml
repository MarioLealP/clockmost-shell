// The app-tray menu (Mario 2026-10-14: an Endfield menu instead of the KDE platform one): a full-screen overlay like
// the control center (click outside or Esc = close) holding one panel under the tray icon. Material = the dock plate
// (DockPlate + shadow), head = the dock preview's .gl (app name, mono caps, rule). Entries from QsMenuOpener;
// submenus open in place with a BACK row. Motion as the control center: fade + 12px slide, 180ms OutCubic.
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: root

    readonly property real s: Math.min(1, width / 1920)
    property real openP: TrayMenu.open ? 1 : 0
    Behavior on openP { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    readonly property bool mine: TrayMenu.screenName === "" || TrayMenu.screenName === screen?.name
    visible: mine && (TrayMenu.open || openP > 0.001)
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "clockmost-traymenu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: TrayMenu.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: Region {
        item: TrayMenu.open ? catcher : null
    }

    MouseArea {
        id: catcher
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: TrayMenu.close()
    }

    Item {
        anchors.fill: parent
        focus: TrayMenu.open
        Keys.onEscapePressed: TrayMenu.stack.length > 1 ? TrayMenu.back() : TrayMenu.close()
    }

    QsMenuOpener {
        id: opener
        menu: TrayMenu.current
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
                return TrayMenu.anchorX < 0 ? maxX : Math.max(16, Math.min(maxX, TrayMenu.anchorX / root.s - width / 2));
            }
            y: 62 - 12 * (1 - root.openP)
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
                        text: TrayMenu.title.toUpperCase()
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

                // BACK, inside a submenu
                TrayMenuRow {
                    visible: TrayMenu.stack.length > 1
                    width: list.width
                    label: "‹  BACK"
                    mono: true
                    onActivated: TrayMenu.back()
                }

                Repeater {
                    model: opener.children
                    TrayMenuRow {
                        required property QsMenuEntry modelData
                        entry: modelData
                        width: list.width
                        onActivated: {
                            if (modelData.hasChildren) {
                                TrayMenu.enter(modelData);
                            } else {
                                modelData.triggered();
                                TrayMenu.close();
                            }
                        }
                    }
                }
            }
        }
    }
}
