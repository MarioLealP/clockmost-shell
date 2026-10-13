// The control center surface: a full-screen overlay (click outside or Esc = close) holding one panel under
// the bar on the right (where the quick-settings mock sits): tab rail | the active tab's content.
// The panel drops in (fade + 12px slide) and its height eases between tabs.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    readonly property real s: Math.min(1, width / 1920)
    property real openP: ControlCenter.open ? 1 : 0
    Behavior on openP { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

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

        // tether from the plate's tri-band down to the panel (only when it hangs under the plate);
        // outside the panel because the panel clips its children
        Rectangle {
            visible: panel.underPlate
            opacity: root.openP
            x: scaled.width / 2
            y: panel.y - 12
            width: 1
            height: 11
            color: Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.35)
        }

        Item {
            id: panel
            // centred under the widget / pointer that opened it, kept 16px inside the screen
            x: {
                const maxX = scaled.width - width - 16;
                return ControlCenter.anchorX < 0 ? maxX : Math.max(16, Math.min(maxX, ControlCenter.anchorX / root.s - width / 2));
            }
            Behavior on x {
                enabled: root.openP > 0.99 // slide when re-targeted while open; appear in place otherwise
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
            // under the hanging clock plate: drop below it (the calendar mock: top 112, tethered to the tri-band)
            readonly property bool underPlate: x < scaled.width / 2 + Theme.plateWidth / 2 && x + width > scaled.width / 2 - Theme.plateWidth / 2
            y: (underPlate ? 112 : 62) - 12 * (1 - root.openP)
            opacity: root.openP
            width: rail.width + 1 + content.width
            height: Math.max(rail.implicitHeight + 20, content.height)
            Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            clip: true

            // swallow clicks so they don't reach the close catcher
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
            }

            Rectangle {
                anchors.fill: parent
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.12)
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.rgba(30 / 255, 31 / 255, 36 / 255, 0.96) }
                    GradientStop { position: 1; color: Qt.rgba(13 / 255, 14 / 255, 17 / 255, 0.97) }
                }
            }

            CCRail {
                id: rail
            }
            Rectangle {
                x: rail.width
                width: 1
                height: parent.height
                color: Qt.rgba(1, 1, 1, 0.08)
            }

            Loader {
                id: content
                x: rail.width + 1
                width: item ? item.width : 432
                height: item ? item.implicitHeight : 200
                onLoaded: if (item.minHeight !== undefined) item.minHeight = Qt.binding(() => rail.implicitHeight + 20)
                sourceComponent: ({ home: homeTab, audio: audioTab, network: networkTab, bluetooth: bluetoothTab, calendar: calendarTab })[ControlCenter.tab] ?? placeholder
            }

            // corner brackets: top-left, bottom-right (14px, 2px)
            Repeater {
                model: [{ x: -1, y: -1, r: 0 }, { x: panel.width - 13, y: panel.height - 13, r: 180 }]
                Item {
                    required property var modelData
                    x: modelData.x
                    y: modelData.y
                    width: 14
                    height: 14
                    rotation: modelData.r
                    Rectangle { width: 14; height: 2; color: Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.5) }
                    Rectangle { width: 2; height: 14; color: Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.5) }
                }
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
        id: calendarTab
        CCCalendar {}
    }
    Component {
        id: placeholder
        CCPlaceholder {
            title: (ControlCenter.tabs.find(t => t.id === ControlCenter.tab)?.label) ?? ""
        }
    }
}
