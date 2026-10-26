// The control center surface: a full-screen overlay (click outside or Esc = close) holding one panel under
// the bar on the right (where the quick-settings mock sits): tab rail | the active tab's content.
// Motion (Mario 2026-10-26): opening, an orange band sweeps down and leaves the panel's background behind it, then
// the Builder plays frames then details; a tab switch rebuilds just the new tab; closing, the band sweeps back up
// and wipes the panel away.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    readonly property real s: Math.min(1, width / 1920)
    property real sweep: 0 // 0 = nothing .. 1 = the whole panel's background is down

    Connections {
        target: ControlCenter
        function onOpenChanged() {
            if (ControlCenter.open) {
                closing.stop();
                builder.finish();
                body.opacity = 0;
                opening.restart();
            } else {
                opening.stop();
                builder.finish();
                closing.restart();
            }
        }
    }
    SequentialAnimation {
        id: opening
        NumberAnimation { target: root; property: "sweep"; from: 0; to: 1; duration: 300; easing.type: Easing.InOutCubic }
        ScriptAction {
            script: {
                builder.speed = 1;
                builder.prepare([panel]);
                body.opacity = 1;
                builder.run();
            }
        }
    }
    ParallelAnimation {
        id: closing
        NumberAnimation { target: body; property: "opacity"; to: 0; duration: 120 }
        NumberAnimation { target: root; property: "sweep"; to: 0; duration: 220; easing.type: Easing.InCubic }
    }

    readonly property bool mine: ControlCenter.screenName === "" || ControlCenter.screenName === screen?.name
    visible: mine && (ControlCenter.open || sweep > 0.001)
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
            y: 84 // v2: just under the bar's plates
            width: rail.width + 1 + content.width
            height: Math.max(rail.implicitHeight, content.height)
            clip: true

            // swallow clicks so they don't reach the close catcher
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
            }

            // v2: a flat graphite panel with a hairline, like the ground's sections - as far down as the sweep got
            Rectangle {
                width: parent.width
                height: parent.height * root.sweep
                color: GroundTheme.bg
                border.width: 1
                border.color: GroundTheme.line
            }

            // everything on the panel (closing: it fades out fast while the band sweeps the background up - a clip
            // here, nested in the panel's, left holes in the background under the tab list)
            Item {
                id: body
                width: parent.width
                height: parent.height

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
                y: parent.height - 9
                width: content.width - 34
                height: 4
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
                // a tab switch while open: rebuild just the new tab, quicker
                onLoaded: if (ControlCenter.open && !opening.running && root.sweep >= 1) Qt.callLater(() => {
                    builder.speed = 1.6;
                    builder.prepare([content]);
                    builder.run();
                })
            }
            }

            // the sweep's front: an orange band riding the bottom edge of what's down so far
            Rectangle {
                objectName: "nobuild"
                visible: root.sweep > 0.001 && root.sweep < 0.999
                y: parent.height * root.sweep - height
                width: parent.width
                height: 14
                color: GroundTheme.acc
            }

            Builder {
                id: builder
                objectName: "nobuild"
                anchors.fill: parent
                z: 10
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
