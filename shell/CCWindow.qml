// The control center surface: a full-screen overlay (click outside or Esc = close) holding one panel under
// the bar on the right (where the quick-settings mock sits): tab rail | the active tab's content.
// The panel drops in (fade + 12px slide) and its height eases between tabs.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    readonly property real s: Math.min(1, width / 1920)
    property real openP: ControlCenter.open ? 1 : 0 // v2: no motion yet - opens/closes instantly

    readonly property bool mine: ControlCenter.screenName === "" || ControlCenter.screenName === screen?.name
    visible: mine && (ControlCenter.open || openP > 0.001)
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "clockmost-cc"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: ControlCenter.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // input everywhere while open (outside = close), nowhere while fading out
    mask: Region {
        item: ControlCenter.open ? catcher : null
    }

    MouseArea {
        id: catcher
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onClicked: ControlCenter.close()
    }

    Item {
        anchors.fill: parent
        focus: ControlCenter.open
        Keys.onEscapePressed: ControlCenter.close()
    }

    Item {
        id: scaled
        width: root.width / root.s
        height: root.height / root.s
        scale: root.s
        transformOrigin: Item.TopLeft

        Item {
            id: panel
            // centred under the widget / pointer that opened it, kept 16px inside the screen
            x: {
                const maxX = scaled.width - width - 16;
                return ControlCenter.anchorX < 0 ? maxX : Math.max(16, Math.min(maxX, ControlCenter.anchorX / root.s - width / 2));
            }
            y: 84 // v2: just under the bar's plates (they end at 70)
            opacity: root.openP
            width: rail.width + 1 + content.width
            height: Math.max(rail.implicitHeight, content.height)
            clip: true

            // swallow clicks so they don't reach the close catcher
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
            }

            // v2: a flat graphite panel with a hairline, like the ground's sections
            Rectangle {
                anchors.fill: parent
                color: GroundTheme.bg
                border.width: 1
                border.color: GroundTheme.line
            }

            CCNav {
                id: rail
                minHeight: content.height
            }
            Rectangle {
                x: rail.width
                width: 1
                height: parent.height
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            // the break: an orange hazard strip along the bottom edge of the content
            Item {
                x: rail.width + 17
                y: parent.height - 18
                width: content.width - 34
                height: 8
                clip: true
                z: 2
                Row {
                    spacing: 8
                    Repeater {
                        model: Math.ceil(parent.parent.width / 16) + 2
                        Rectangle { width: 8; height: 20; y: -6; color: GroundTheme.acc; rotation: 45 }
                    }
                }
            }
            Loader {
                id: content
                x: rail.width + 1
                width: item ? item.width : 432
                height: item ? item.implicitHeight : 200
                // v2: the nav stretches to the content (CCNav.minHeight), the content keeps its own height
                sourceComponent: ({ home: homeTab, audio: audioTab, network: networkTab, bluetooth: bluetoothTab, media: mediaTab, calendar: calendarTab, clipboard: clipboardTab, notifications: notificationsTab })[ControlCenter.tab] ?? placeholder
            }

        }
    }

    Component {
        id: homeTab
        CCHome {}
    }
    Component {
        id: audioTab
        CCAudio {}
    }
    Component {
        id: networkTab
        CCNetwork {}
    }
    Component {
        id: bluetoothTab
        CCBluetooth {}
    }
    Component {
        id: mediaTab
        CCMedia {}
    }
    Component {
        id: calendarTab
        CCCalendar {}
    }
    Component {
        id: clipboardTab
        CCClipboard {}
    }
    Component {
        id: notificationsTab
        CCNotifications {}
    }
    Component {
        id: placeholder
        CCPlaceholder {
            title: (ControlCenter.tabs.find(t => t.id === ControlCenter.tab)?.label) ?? ""
        }
    }
}
