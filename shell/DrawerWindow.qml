// The app drawer (v2, mock design/v2-2026-10-25/drawer.html): search first, logos only. The query is the poster;
// under it a deck of logo squares - the featured app dead centre and big, the rest shrinking away on both sides like a
// carousel (it wraps: next ones right, the ones before / the list's end left, each app once); the featured app's name
// and a spec line under it. No query = every app, most launched first. ← → (or the wheel) walk the deck, Enter opens
// the featured app, a side square click features it, the featured one's click opens it. Solid colours only (cm-1jun).
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    readonly property real s: Math.min(1, width / 1920, height / 1080)
    property string query: ""
    property int selected: 0
    readonly property var results: Apps.search(query)
    readonly property var featured: results[selected] ?? null

    // the deck's squares, by distance from the centre
    readonly property var sizes: [232, 148, 116, 92, 76]
    readonly property int gap: 12
    // [{entry, index, dist, x, size}] - x from the deck's centre; each app shown once, the shorter side left empty
    readonly property var deck: {
        const n = results.length;
        if (!n)
            return [];
        const at = Math.min(selected, n - 1);
        const out = [{ entry: results[at], index: at, dist: 0, x: -sizes[0] / 2, size: sizes[0] }];
        const used = new Set([at]);
        let r = sizes[0] / 2 + gap, l = -sizes[0] / 2 - gap;
        for (let d = 1; d < sizes.length; d++) {
            const ri = (at + d) % n, li = ((at - d) % n + n) % n;
            if (!used.has(ri)) {
                used.add(ri);
                out.push({ entry: results[ri], index: ri, dist: d, x: r, size: sizes[d] });
            }
            r += sizes[d] + gap;
            if (!used.has(li)) {
                used.add(li);
                out.push({ entry: results[li], index: li, dist: -d, x: l - sizes[d], size: sizes[d] });
            }
            l -= sizes[d] + gap;
        }
        return out;
    }

    function step(d) {
        const n = results.length;
        if (n)
            selected = ((selected + d) % n + n) % n;
    }
    function windowsOf(e) {
        return e ? (DockApps.slots.find(s => s.key === e.id)?.windows.length ?? 0) : 0;
    }
    function launch(e) {
        Apps.launch(e);
        Drawer.close();
    }

    visible: Drawer.open
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "clockmost-drawer"
    WlrLayershell.layer: WlrLayer.Overlay
    // exclusive from the moment the surface maps (it only exists while open): flipping it on in the same tick the
    // window appears left KWin's keyboard focus on the window underneath
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    onVisibleChanged: if (visible) Qt.callLater(() => search.forceActiveFocus())

    // input everywhere but the bar and dock strips (they stay usable and close the drawer themselves)
    mask: Region {
        item: Drawer.open ? catcher : null
        Region {
            intersection: Intersection.Subtract
            width: root.width
            height: Drawer.topInset(root.width)
        }
        Region {
            intersection: Intersection.Subtract
            y: root.height - Drawer.bottomInset(root.width)
            width: root.width
            height: Drawer.bottomInset(root.width)
        }
    }

    Connections {
        target: Drawer
        function onOpenChanged() {
            if (Drawer.open) {
                search.text = "";
                root.query = "";
                root.selected = 0;
                search.forceActiveFocus();
            }
        }
    }

    MouseArea {
        id: catcher
        anchors.fill: parent
        onClicked: Drawer.close()
    }

    Item {
        id: scaled
        width: root.width / root.s
        height: root.height / root.s
        scale: root.s
        transformOrigin: Item.TopLeft

        Rectangle {
            id: panel
            width: 1296
            height: col.height + 36 + 40
            x: Math.round((parent.width - width) / 2)
            y: Math.round((parent.height - height) / 2)
            color: GroundTheme.bg
            border.width: 1
            border.color: GroundTheme.lineSolid

            // swallow clicks inside; the wheel walks the deck. MouseArea.onWheel, not a WheelHandler (on metal that
            // never fired)
            MouseArea {
                anchors.fill: parent
                property real acc: 0
                onWheel: wheel => {
                    acc += wheel.angleDelta.y;
                    while (Math.abs(acc) >= 120) {
                        root.step(acc > 0 ? -1 : 1);
                        acc -= acc > 0 ? 120 : -120;
                    }
                }
            }

            Column {
                id: col
                x: 48
                y: 36
                width: parent.width - 96

                // the query as the poster: › QUERY▌ (centred); empty = a dark SEARCH
                Item {
                    width: parent.width
                    height: 104
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: parent.height
                        spacing: 18
                        Text {
                            anchors.baseline: shown.baseline
                            text: "›"
                            color: GroundTheme.acc
                            font.family: GroundTheme.display
                            font.weight: Font.Black
                            font.variableAxes: { "wght": 900 }
                            font.pixelSize: 72
                        }
                        Text {
                            id: shown
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.query !== "" ? root.query.toUpperCase() : "SEARCH"
                            color: root.query !== "" ? GroundTheme.ink : "#2e2e2b"
                            font.family: GroundTheme.display
                            font.weight: Font.Black
                            font.variableAxes: { "wdth": 70, "wght": 900 }
                            font.pixelSize: 104
                        }
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14
                            height: 84
                            color: GroundTheme.acc
                            transform: Translate { x: -12 } // hugs the last letter, like a terminal block caret
                        }
                    }
                    // the real input: 1px wide and clipped (the poster above draws what it holds)
                    TextInput {
                        id: search
                        width: 1
                        height: 1
                        clip: true
                        color: GroundTheme.bg
                        cursorDelegate: Item {}
                        onTextChanged: {
                            root.query = text;
                            root.selected = 0;
                        }
                        Keys.onEscapePressed: Drawer.close()
                        Keys.onReturnPressed: if (root.featured) root.launch(root.featured)
                        Keys.onEnterPressed: if (root.featured) root.launch(root.featured)
                        Keys.onLeftPressed: root.step(-1)
                        Keys.onRightPressed: root.step(1)
                        Keys.onUpPressed: root.step(-1)
                        Keys.onDownPressed: root.step(1)
                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_PageDown || event.key === Qt.Key_Tab) {
                                root.step(event.key === Qt.Key_Tab ? 1 : 5);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_PageUp || event.key === Qt.Key_Backtab) {
                                root.step(event.key === Qt.Key_Backtab ? -1 : -5);
                                event.accepted = true;
                            }
                        }
                    }
                }

                // the rule, its orange mark over the featured square
                Item {
                    width: parent.width
                    height: 18 + 36
                    Rectangle { y: 18; width: parent.width; height: 1; color: GroundTheme.lineSolid }
                    Rectangle { x: (parent.width - 232) / 2; y: 17; width: 232; height: 3; color: GroundTheme.acc }
                }

                // the deck
                Item {
                    id: deckRow
                    width: parent.width
                    height: 232
                    Repeater {
                        model: root.deck
                        DrawerSquare {
                            required property var modelData
                            x: deckRow.width / 2 + modelData.x
                            y: (232 - modelData.size) / 2
                            width: modelData.size
                            height: modelData.size
                            entry: modelData.entry
                            featured: modelData.dist === 0
                            number: modelData.index + 1
                            windows: root.windowsOf(modelData.entry)
                            onClicked: modelData.dist === 0 ? root.launch(modelData.entry) : (root.selected = modelData.index)
                        }
                    }
                    Text {
                        visible: root.results.length === 0
                        anchors.centerIn: parent
                        text: "NOTHING MATCHES"
                        color: GroundTheme.ink2
                        font.family: GroundTheme.mono
                        font.pixelSize: 12
                        font.letterSpacing: 3
                    }
                }

                // the featured app: its name as the second poster, a spec line under it
                Item { width: 1; height: 24 }
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: (root.featured?.name ?? " ").toUpperCase()
                    elide: Text.ElideRight
                    color: GroundTheme.ink
                    font.family: GroundTheme.display
                    font.weight: Font.Black
                    font.variableAxes: { "wdth": 75, "wght": 900 }
                    font.pixelSize: 64
                }
                Item { width: 1; height: 12 }
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    textFormat: Text.StyledText
                    text: {
                        const e = root.featured;
                        if (!e)
                            return " ";
                        const n = Apps.usage[e.id] || 0, w = root.windowsOf(e);
                        return [Apps.code(e), (e.genericName || e.comment || "").toUpperCase(), n + (n === 1 ? " LAUNCH" : " LAUNCHES"),
                            w ? "<font color=\"" + GroundTheme.acc + "\">" + w + " OPEN</font>" : "NOT RUNNING"]
                            .filter(x => x).join("  ·  ");
                    }
                    color: GroundTheme.ink2
                    font.family: GroundTheme.mono
                    font.pixelSize: 11
                    font.letterSpacing: 2
                }

                // foot: the scrubber (a tick per app, the featured one orange), the count, the keys
                Item { width: 1; height: 40 }
                Rectangle { width: parent.width; height: 1; color: GroundTheme.lineSolid }
                Item {
                    width: parent.width
                    height: 38
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Repeater {
                            model: Math.min(root.results.length, 24)
                            Rectangle {
                                required property int index
                                // past 24 apps a tick stands for a stretch of the list
                                readonly property bool on: Math.floor(root.selected * Math.min(root.results.length, 24) / root.results.length) === index
                                anchors.verticalCenter: parent.verticalCenter
                                width: on ? 28 : 14
                                height: 6
                                color: on ? GroundTheme.acc : GroundTheme.lineSolid
                            }
                        }
                        Item { width: 8; height: 1 }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: String(root.selected + 1).padStart(2, "0") + " / " + String(root.results.length).padStart(2, "0")
                            color: GroundTheme.ink2
                            font.family: GroundTheme.mono
                            font.pixelSize: 10
                            font.letterSpacing: 2
                        }
                        Item { width: 14; height: 1 }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            textFormat: Text.StyledText
                            text: root.query !== "" ? "<font color=\"" + GroundTheme.acc + "\">" + root.results.length + "</font>  MATCHES"
                                : "MOST LAUNCHED FIRST  ·  <font color=\"" + GroundTheme.acc + "\">" + Apps.all.length + "</font>  APPS"
                            color: GroundTheme.ink2
                            font.family: GroundTheme.mono
                            font.pixelSize: 11
                            font.letterSpacing: 3
                        }
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "↵ OPEN     ← → PICK     ESC CLOSE"
                        color: GroundTheme.ink2
                        font.family: GroundTheme.mono
                        font.pixelSize: 10
                        font.letterSpacing: 2
                    }
                }
            }

            // the hazard strip along the bottom edge
            Item {
                x: 48
                y: parent.height - 12
                width: parent.width - 96
                height: 4
                clip: true
                Row {
                    spacing: 8
                    Repeater {
                        model: Math.ceil(parent.parent.width / 16) + 2
                        Rectangle { width: 8; height: 20; y: -6; color: GroundTheme.acc; rotation: 45 }
                    }
                }
            }
        }
    }
}
