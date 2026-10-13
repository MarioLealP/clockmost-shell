// The Endfield HUD top bar (ds-topbar-v2). The window is taller than the band so the clock plate and
// ring can hang below it; only the band reserves space, and only the band + plate take input.
// Laid out at the mock's 1920px; narrower screens (the 1280 test VM) get the whole bar scaled down.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    readonly property real s: Math.min(1, width / 1920)
    readonly property int reach: 162 // ring reach below the top edge, in mock px

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Math.ceil(reach * s)
    exclusiveZone: Math.ceil(Theme.band * s)
    color: "transparent"
    WlrLayershell.namespace: "clockmost-bar"
    WlrLayershell.layer: WlrLayer.Top

    // frosted band (CSS backdrop-filter: blur(22px)) via KWin's ext-background-effect
    BackgroundEffect.blurRegion: Region {
        item: band
    }

    mask: Region {
        item: band
        Region {
            item: plate
        }
    }

    Item {
        id: hud
        width: root.width / root.s
        height: root.reach
        scale: root.s
        transformOrigin: Item.TopLeft

        BarRing {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
        }

        BarBand {
            id: band
            anchors.left: parent.left
            anchors.right: parent.right
        }

        BarLeft {
            id: left
            x: 20
            anchors.verticalCenter: band.verticalCenter
        }

        BarWing {
            leftSide: true
            visible: x > left.x + left.width + 12 // wings give way to the widget groups
            label: KWin.currentDesktop
                ? "WS " + String(KWin.currentDesktop.number).padStart(2, "0") + " · " + KWin.windowsOn(KWin.current).length + " WIN"
                : ""
            anchors.right: plate.left
            anchors.rightMargin: 16
            anchors.verticalCenter: band.verticalCenter
        }

        ClockPlate {
            id: plate
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
        }

        BarWing {
            id: rightWing
            leftSide: false
            visible: x + width + 12 < right.x
            anchors.left: plate.right
            anchors.leftMargin: 16
            anchors.verticalCenter: band.verticalCenter
        }

        BarRight {
            id: right
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.verticalCenter: band.verticalCenter
        }
    }
}
