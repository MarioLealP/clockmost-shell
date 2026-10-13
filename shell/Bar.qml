// The Endfield HUD top bar (ds-topbar-v2: "appears on Win / top edge").
// Smart hide: shown while no window covers its area; covered = slides away. Revealed by a Win-key tap
// (bridge event) or the pointer touching the top edge; hides again once the pointer leaves.
// The window is taller than the band so the clock plate and ring can hang below it. It reserves no space.
// Laid out at the mock's 1920px; narrower screens (the 1280 test VM) get the whole bar scaled down.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    readonly property real s: Math.min(1, width / 1920)
    readonly property int reach: 162 // ring reach below the top edge, in mock px
    readonly property int plateReach: Theme.plateHeight + Theme.triBand

    // does any visible window on this desktop and screen overlap the band + plate area?
    readonly property bool covered: {
        const scr = root.screen;
        if (!scr)
            return false;
        const bottom = scr.y + plateReach * s;
        return KWin.windowsOn(KWin.current).some(w => !w.minimized && w.output === scr.name
            && w.y < bottom && w.y + w.h > scr.y && w.x < scr.x + scr.width && w.x + w.w > scr.x);
    }
    property bool revealed: false
    readonly property bool hovered: hudHover.hovered || edge.containsMouse
    readonly property bool shown: !covered || revealed || hovered || ControlCenter.open || Drawer.open

    // 0 = hidden .. 1 = shown. Reveal: the clock plate drops first, the band + groups follow (Mario);
    // hide mirrors it: the band leaves first, then the plate pulls up. No overshoot (Mario: no bounce).
    property real bandP: shown ? 1 : 0
    property real plateP: shown ? 1 : 0
    Behavior on bandP {
        SequentialAnimation {
            PauseAnimation { duration: root.shown ? 90 : 0 }
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }
    }
    Behavior on plateP {
        SequentialAnimation {
            PauseAnimation { duration: root.shown ? 0 : 90 }
            NumberAnimation { duration: 280; easing.type: Easing.OutQuart }
        }
    }

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Math.ceil(reach * s)
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.namespace: "clockmost-bar"
    WlrLayershell.layer: WlrLayer.Top

    onHoveredChanged: if (!hovered) hideDelay.restart()
    Connections {
        target: KWin
        // Win = the app drawer (ds-app-drawer), and the bar comes with it while it's open
        function onRevealRequested() {
            Drawer.toggle();
        }
    }
    // a Win-reveal stays until the pointer has been away a moment
    Timer {
        id: hideDelay
        interval: root.hovered ? 450 : 2500
        onTriggered: if (!root.hovered) root.revealed = false
    }

    // frosted band (CSS backdrop-filter: blur(22px)) via KWin's ext-background-effect
    BackgroundEffect.blurRegion: root.bandP > 0.01 ? shownBlur : null
    Region {
        id: shownBlur
        item: band
    }

    // input: hidden = only the top-edge strip; shown = band + plate
    mask: root.bandP > 0.01 ? shownMask : hiddenMask
    Region {
        id: shownMask
        item: band
        Region { item: plate }
        Region { item: edge }
    }
    Region {
        id: hiddenMask
        item: edge
    }

    MouseArea {
        id: edge
        anchors.left: parent.left
        anchors.right: parent.right
        height: 2
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        z: 10
    }

    Item {
        id: hud
        width: root.width / root.s
        height: root.reach
        scale: root.s
        transformOrigin: Item.TopLeft

        HoverHandler {
            id: hudHover
        }
        // right-click anywhere on the bar = the control center's home (Noctalia habit)
        TapHandler {
            acceptedButtons: Qt.RightButton
            onTapped: eventPoint => ControlCenter.show("home", root.screen?.name ?? "", eventPoint.scenePosition.x)
        }

        BarRing {
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: root.plateP
        }

        // band layer: the band and everything sitting on it slide down together
        Item {
            id: bandLayer
            width: parent.width
            height: Theme.band
            y: -Theme.band * 1.2 * (1 - root.bandP)

            BarBand {
                id: band
                width: parent.width
            }

            BarLeft {
                id: left
                x: 20 - 12 * (1 - root.bandP)
                opacity: root.bandP
                anchors.verticalCenter: band.verticalCenter
            }

            BarWing {
                id: leftWing
                leftSide: true
                x: hud.width / 2 - Theme.plateWidth / 2 - 16 - width
                // shrinks to the space between the left group and the plate
                room: hud.width / 2 - Theme.plateWidth / 2 - 16 - (20 + left.width + 12)
                opacity: root.plateP * fitOpacity
                label: KWin.currentDesktop
                    ? "WS " + String(KWin.currentDesktop.number).padStart(2, "0") + " · " + KWin.windowsOn(KWin.current).length + " WIN"
                    : ""
                anchors.verticalCenter: band.verticalCenter
            }

            BarWing {
                id: rightWing
                leftSide: false
                x: hud.width / 2 + Theme.plateWidth / 2 + 16
                room: (hud.width - 20 - right.width - 12) - x
                opacity: root.plateP * fitOpacity
                anchors.verticalCenter: band.verticalCenter
            }

            BarRight {
                id: right
                x: hud.width - 20 - width + 12 * (1 - root.bandP)
                opacity: root.bandP
                anchors.verticalCenter: band.verticalCenter
            }
        }

        ClockPlate {
            id: plate
            anchors.horizontalCenter: parent.horizontalCenter
            y: -root.plateReach * 1.1 * (1 - root.plateP)
        }
    }
}
