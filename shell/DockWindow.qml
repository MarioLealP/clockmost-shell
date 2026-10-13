// The Endfield dock (ds-dock-v2: "appears on Win / bottom edge"), the bar's partner at the bottom.
//   .dock      centred, 14px off the bottom, 84px tall, padding 0 16px, gap 10px, items centred
//   .cap       end caps: label / barcode (52x7) / micro print, 5px apart, padding 0 6px
//   .div       1x44 rgba(255,255,255,.10) dividers, margin 0 2px
//   .handle    hidden state: a 140x4 dashed handle (6 on / 3 off, rgba(241,241,244,.4)) 4px off the bottom
// Smart hide like the bar: shown while no window covers its area; covered = slides down out of the way, leaving
// the handle. Revealed by the bottom edge, hovering it, or the app drawer (Win) being open. No bounce.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    readonly property real s: Math.min(1, width / 1920)
    readonly property int above: 56 // room above the plate for the focus lift + hover labels
    readonly property int plateH: 84
    readonly property int gapBottom: 14

    readonly property real plateW: row.implicitWidth + 32
    // the plate's rect on screen, in window coordinates when shown
    readonly property real px: (width - plateW * s) / 2
    readonly property real py: height - (gapBottom + plateH) * s

    readonly property bool covered: {
        const scr = root.screen;
        if (!scr)
            return false;
        const top = scr.y + scr.height - (gapBottom + plateH) * s;
        const left = scr.x + px, right = left + plateW * s;
        return KWin.windowsOn(KWin.current).some(w => !w.minimized && w.output === scr.name
            && w.y + w.h > top && w.y < scr.y + scr.height && w.x < right && w.x + w.w > left);
    }
    readonly property bool hovered: plateHover.hovered || edge.containsMouse
    property bool lingering: false
    readonly property bool shown: !covered || hovered || lingering || Drawer.open

    property real p: shown ? 1 : 0
    Behavior on p { NumberAnimation { duration: 280; easing.type: Easing.OutQuart } }

    onHoveredChanged: if (!hovered) {
        lingering = true;
        linger.restart();
    }
    Timer {
        id: linger
        interval: 450
        onTriggered: root.lingering = false
    }

    anchors {
        bottom: true
        left: true
        right: true
    }
    implicitHeight: Math.ceil((above + plateH + gapBottom) * s)
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.namespace: "clockmost-dock"
    WlrLayershell.layer: WlrLayer.Top

    // the plate's backdrop-filter: blur(22px) (saturate(1.2) has no KWin counterpart)
    BackgroundEffect.blurRegion: p > 0.3 ? blurRect : null
    Region {
        id: blurRect
        x: Math.round(root.px)
        y: Math.round(root.py + slide.y * root.s)
        width: Math.round(root.plateW * root.s)
        height: Math.round(root.plateH * root.s)
    }

    mask: p > 0.01 ? shownMask : hiddenMask
    Region {
        id: shownMask
        x: Math.round(root.px)
        y: Math.round(root.py + slide.y * root.s)
        width: Math.round(root.plateW * root.s)
        height: Math.round(root.plateH * root.s)
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
        anchors.bottom: parent.bottom
        height: 2
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        z: 10
    }

    Item {
        id: hud
        width: root.width / root.s
        height: root.above + root.plateH + root.gapBottom
        scale: root.s
        transformOrigin: Item.TopLeft

        // hidden state handle
        Canvas {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4
            width: 140
            height: 4
            opacity: 1 - root.p
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                ctx.fillStyle = Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.4);
                for (let x = 0; x < width; x += 9)
                    ctx.fillRect(x, 0, Math.min(6, width - x), height);
            }
        }

        Item {
            id: slide
            width: parent.width
            height: parent.height
            y: (root.plateH + root.gapBottom + 12) * (1 - root.p)
            opacity: root.p

            DockPlate {
                id: plate
                x: (parent.width - width) / 2
                y: root.above
                width: root.plateW
                height: root.plateH

                HoverHandler {
                    id: plateHover
                }
            }

            Row {
                id: row
                x: plate.x + 16
                anchors.verticalCenter: plate.verticalCenter
                spacing: 10

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    leftPadding: 6
                    rightPadding: 6
                    spacing: 5
                    Text {
                        text: "DOCK"
                        color: Theme.yellow
                        font.family: Theme.mono
                        font.weight: Font.Bold
                        font.pixelSize: 10
                        font.letterSpacing: Theme.em(10, 0.2)
                    }
                    Barcode {
                        width: 52
                        height: 7
                        color: Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.5)
                    }
                    Micro {
                        text: String(DockApps.pins.length).padStart(2, "0") + " PINNED"
                    }
                }
                DockDivider {}
                DockDrawerButton {
                    anchors.verticalCenter: parent.verticalCenter
                }
                DockDivider {}
                Repeater {
                    model: DockApps.slots
                    DockSlot {
                        required property var modelData
                        slot: modelData
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                DockDivider {}
                DockDownloads {
                    anchors.verticalCenter: parent.verticalCenter
                }
                DockDivider {}
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    leftPadding: 6
                    rightPadding: 6
                    spacing: 5
                    Micro {
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        textFormat: Text.StyledText
                        text: "<font color='" + Theme.cyan + "'>" + DockApps.running + " RUNNING</font> · <font color='"
                            + Theme.magenta + "'>" + KWin.windows.length + " WIN</font>"
                    }
                    Barcode {
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        width: 52
                        height: 7
                        color: Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.5)
                    }
                    Micro {
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        text: "DK-" + String(Quickshell.screens.indexOf(root.screen) + 1).padStart(2, "0")
                    }
                }
            }
        }
    }
}
