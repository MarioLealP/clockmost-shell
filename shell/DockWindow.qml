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
    readonly property int above: 270 // room above the plate: focus lift, hover labels, the window preview panel
    readonly property int plateH: Theme.dockPlateHeight
    readonly property int gapBottom: Theme.dockGapBottom

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
    readonly property bool hovered: plateHover.hovered || edge.containsMouse || preview.hovered

    // window preview (DockPreview): opens 250ms after hovering a slot with windows (at once when already open, so
    // sliding along the dock follows), stays while the pointer is on the slot or the panel
    property var hoverItem: null
    property string previewKey: ""
    property real previewCx: 0
    readonly property var previewSlot: previewKey && dragIndex < 0 && !menuHere
        ? DockApps.slots.find(s => s.key === previewKey && s.windows.length) ?? null : null

    // drag to reorder the pinned slots (Mario 2026-10-15): the dragged slot follows the pointer, the ones between
    // its old and new place slide one pitch over to make room; the order is saved on release (DockApps.movePin)
    readonly property int pitch: 56 + 10 // slot + row spacing
    property int dragIndex: -1
    // the pinned slots on screen: frozen while a drag runs - slots rebuild on any window change (a title, a new
    // window), and a rebuild would destroy the dragged slot and its mouse grab
    property var pinnedShown: DockApps.pinnedSlots
    Connections {
        target: DockApps
        function onPinnedSlotsChanged() {
            if (root.dragIndex < 0)
                root.pinnedShown = DockApps.pinnedSlots;
        }
    }
    property real dragDx: 0
    readonly property int dragTo: dragIndex < 0 ? -1
        : Math.max(0, Math.min(pinnedShown.length - 1, Math.round(dragIndex + dragDx / pitch)))
    function shiftFor(i) {
        if (dragIndex < 0)
            return 0;
        if (i === dragIndex)
            return dragDx;
        if (i > dragIndex && i <= dragTo)
            return -pitch;
        if (i < dragIndex && i >= dragTo)
            return pitch;
        return 0;
    }
    function slotHover(item) {
        if (item.hovered) {
            hoverItem = item;
            if (previewKey)
                showPreview();
            else
                previewOpen.restart();
        } else if (hoverItem === item) {
            hoverItem = null;
            previewOpen.stop();
            previewClose.restart();
        }
    }
    function showPreview() {
        const it = hoverItem;
        if (!it || !it.slot.windows.length) {
            previewKey = "";
            return;
        }
        previewKey = it.slot.key;
        previewIcon = it.icon;
        previewCx = it.mapToItem(slide, it.width / 2, 0).x;
    }
    property string previewIcon: ""
    Connections {
        target: DockApps
        function onForcedPreviewChanged() {
            const it = slotItems().find(i => i.slot.key === DockApps.forcedPreview);
            if (it) {
                root.hoverItem = it;
                root.showPreview();
                root.hoverItem = null;
            } else {
                root.previewKey = "";
            }
        }
    }
    function slotItems() {
        return row.children.filter(c => c.slot !== undefined);
    }
    Timer {
        id: previewOpen
        interval: 250
        onTriggered: root.showPreview()
    }
    Timer {
        id: previewClose
        interval: 300
        onTriggered: if (!root.hoverItem && !preview.hovered) root.previewKey = ""
    }
    property bool lingering: false
    readonly property bool shown: !covered || hovered || lingering || Drawer.open || menuHere || dragIndex >= 0
    readonly property bool menuHere: DockMenu.open && (DockMenu.screenName === "" || DockMenu.screenName === screen?.name)

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
        id: previewRect
        x: Math.round(preview.x * root.s)
        y: Math.round((preview.y + slide.y) * root.s)
        width: root.previewSlot ? Math.round(preview.width * root.s) : 0
        height: root.previewSlot ? Math.round(preview.height * root.s) : 0
    }
    Region {
        id: blurRect
        Region {
            x: previewRect.x
            y: previewRect.y
            width: previewRect.width
            height: previewRect.height
        }
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
        Region {
            x: previewRect.x
            y: previewRect.y
            width: previewRect.width
            height: previewRect.height
        }
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

            DockPreview {
                id: preview
                slot: root.previewSlot
                icon: root.previewIcon
                // above the slot, kept on screen
                x: Math.max(16, Math.min(parent.width - width - 16, root.previewCx - width / 2))
                y: plate.y - 20 - height
                pointerX: root.previewCx - x
                opacity: root.previewSlot ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 160 } }
                onHoveredChanged: if (!hovered) previewClose.restart()
            }

            Row {
                id: row
                x: plate.x + 16
                anchors.verticalCenter: plate.verticalCenter
                // slots are 56 tile + 8 marks: shift so the tiles (not tile+marks) sit on the plate's centre line
                anchors.verticalCenterOffset: 4
                spacing: 10

                Column {
                    visible: false // v2: no side labels on the dock
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
                DockDrawerButton {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: -4 // on the tiles' centre line
                }
                DockDivider {}
                Repeater {
                    model: root.pinnedShown
                    DockSlot {
                        id: dslot
                        required property var modelData
                        required property int index
                        slot: modelData
                        anchors.verticalCenter: parent.verticalCenter
                        onHoveredChanged: root.slotHover(dslot)
                        shift: root.shiftFor(index)
                        dragging: root.dragIndex === index
                        z: dragging ? 5 : 0
                        onDragStarted: {
                            root.dragDx = 0;
                            root.dragIndex = index;
                        }
                        onDragMoved: dx => root.dragDx = dx
                        onDragEnded: {
                            const to = root.dragTo;
                            if (to !== index)
                                DockApps.movePin(modelData.key, to);
                            root.dragIndex = -1;
                            root.dragDx = 0;
                            root.pinnedShown = DockApps.pinnedSlots;
                        }
                    }
                }
                // pinned | open-but-not-pinned (Mario: couldn't tell them apart) - the mock's own divider
                DockDivider {
                    visible: DockApps.openSlots.length > 0
                }
                Repeater {
                    model: DockApps.openSlots
                    DockSlot {
                        id: dslot
                        required property var modelData
                        slot: modelData
                        anchors.verticalCenter: parent.verticalCenter
                        onHoveredChanged: root.slotHover(dslot)
                    }
                }
                DockDivider {}
                // the task-manager button, in the mock's downloads-stack spot (Mario)
                DockTasks {
                    anchors.verticalCenter: parent.verticalCenter
                }
                Column {
                    visible: false // v2: no side labels on the dock
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

    // a press here closes the app drawer and still reaches the bar / dock
    DrawerCloser {}
}
