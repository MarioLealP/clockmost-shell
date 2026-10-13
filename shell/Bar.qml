// The Endfield HUD top bar (ds-topbar-v2). The window is taller than the band so the clock plate and
// ring can hang below it; only the band reserves space, and only the band + plate take input.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 162 // ring reach below the top edge
    exclusiveZone: Theme.band
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

    BarRing {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 0
    }

    BarBand {
        id: band
        anchors.left: parent.left
        anchors.right: parent.right
    }

    BarMark {
        x: 20
        anchors.verticalCenter: band.verticalCenter
    }

    BarWing {
        leftSide: true
        label: "WS 01 · 2 WIN"
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
        leftSide: false
        anchors.left: plate.right
        anchors.leftMargin: 16
        anchors.verticalCenter: band.verticalCenter
    }
}
