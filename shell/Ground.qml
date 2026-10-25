// The v2 desktop ("ground"): a Background layer surface under the windows, above plasmashell's desktop (spike
// 2026-10-25). The main screen gets the poster; side screens only the base, dots and corners (Mario: no line there).
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    property bool main: false

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "clockmost-ground"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    anchors { left: true; right: true; top: true; bottom: true }
    color: GroundTheme.bg

    DotGrid {
        anchors.fill: parent
        pitch: 24
        radius: 1.2
        color: GroundTheme.line
    }

    RegMarks { anchors.fill: parent }

    // everything that pans when an HA section opens (the pan itself is a later step)
    Item {
        id: pan
        visible: root.main
        width: parent.width
        height: parent.height

        GroundLine { x: 920; y: -140 }

        Text {
            x: 96
            y: 590
            text: "✖✖✖✖✖✖✖✖✖✖\n✖✖✖✖✖✖✖✖✖✖"
            color: GroundTheme.faint
            font.family: GroundTheme.display
            font.pixelSize: 40
            font.weight: Font.Black
            font.letterSpacing: 2
            lineHeight: 0.8
        }

        HeroSlices { x: 1640; y: 170 }
        XMarks {}

        GroundBarcode { x: 96; anchors.bottom: parent.bottom; anchors.bottomMargin: 140 }
        NowPlayingBlock { x: 760; anchors.bottom: parent.bottom; anchors.bottomMargin: 30 }
        DateStack { anchors.right: parent.right; anchors.rightMargin: 110; anchors.bottom: parent.bottom; anchors.bottomMargin: 150 }
    }

    // fixed: the controls don't pan
    HaList { visible: root.main; x: 84; y: 150 }
    FeltColumn { visible: root.main; anchors.right: parent.right; anchors.rightMargin: 96; y: 150 }
}
