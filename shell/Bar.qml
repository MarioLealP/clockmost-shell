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
    readonly property bool shown: GroundTheme.introDone && (!covered || revealed || hovered || ControlCenter.open || Drawer.open)

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
    WlrLayershell.namespace: "clockmost-bar-v2" // v2: renamed - also forced a fresh surface, dropping the old band blur
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
    // v2: no frosted band. An explicit empty region, not null: null left KWin's startup blur (the old 52px band) in place
    BackgroundEffect.blurRegion: noBlur
    Region {
        id: noBlur
    }
    Region {
        id: shownBlur
        item: band
    }

    // input: hidden = only the top-edge strip; shown = the whole bar height, fixed (not the sliding band: mid-slide
    // the band is still above the screen, and the pointer coming down from the edge fell out of the bar and hid it)
    mask: root.bandP > 0.01 ? shownMask : hiddenMask
    Region {
        id: shownMask
        width: root.width
        height: Math.ceil(Theme.band * root.s)
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
            visible: false // v2: no ring / plate / wings / now playing - the clock + media live on the ground
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
                opacity: 0 // v2: no band - the plates sit straight on the ground (its geometry still drives the input mask)
            }

            BarLeft {
                id: left
                x: 40 - 12 * (1 - root.bandP) // v2: inset to the ground's corner marks
                opacity: root.bandP
                anchors.verticalCenter: band.verticalCenter
            }

            BarWing {
                id: leftWing
                visible: false
                leftSide: true
                x: hud.width / 2 - Theme.plateWidth / 2 - 16 - width
                // shrinks to the space between the left group + now playing and the plate
                room: hud.width / 2 - Theme.plateWidth / 2 - 16 - (20 + left.width + 12 + media.width + 12)
                opacity: root.plateP * fitOpacity
                label: KWin.currentDesktop
                    ? "WS " + String(KWin.currentDesktop.number).padStart(2, "0") + " · " + KWin.windowsOn(KWin.current).length + " WIN"
                    : ""
                anchors.verticalCenter: band.verticalCenter
            }

            // now playing, left of the wing: media > arrow > clock (Mario 2026-10-14; the right side needs the room for
            // the app tray)
            NowPlaying {
                id: media
                visible: false
                x: leftWing.x - 12 - width
                opacity: root.bandP
                anchors.verticalCenter: band.verticalCenter
            }

            BarWing {
                id: rightWing
                visible: false
                leftSide: false
                x: hud.width / 2 + Theme.plateWidth / 2 + 16
                room: (hud.width - 20 - right.width - 12) - x
                opacity: root.plateP * fitOpacity
                anchors.verticalCenter: band.verticalCenter
            }

            BarRight {
                id: right
                x: hud.width - 40 - width + 12 * (1 - root.bandP)
                opacity: root.bandP
                anchors.verticalCenter: band.verticalCenter
            }
        }

        ClockPlate {
            id: plate
            visible: false
            anchors.horizontalCenter: parent.horizontalCenter
            y: -root.plateReach * 1.1 * (1 - root.plateP)
        }
    }

    // a press here closes the app drawer and still reaches the bar / dock
    DrawerCloser {}
}
