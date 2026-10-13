// The app drawer (ds-app-drawer): centred 980x600, solid white head fading into frosted glass, a grid of 120px
// sockets with app tiles on top, search at the bottom. Motion per the mock: open = fade 280ms + slide up 60px
// (500ms ease-out), then the tiles fade in over their sockets (150ms); close = fade in place (exits never move).
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    readonly property real s: Math.min(1, width / 1920, height / 1080)
    readonly property int cols: 7
    readonly property int rows: 3
    property string query: ""
    property int selected: 0
    // the keyboard selection only shows once it means something: a query typed (Enter = top match) or arrows used
    property bool keyed: false
    readonly property bool showSelection: keyed || query !== ""
    readonly property var results: Apps.search(query)
    // scrolling (Mario: more apps than the 7x3 grid holds): whole-row steps - the sockets and the glass holes stay put,
    // the apps step through them. Wheel / arrows / PageUp-PageDown; `selected` indexes `results`, not the cells.
    property int rowOffset: 0
    readonly property int totalRows: Math.ceil(results.length / cols)
    readonly property int maxOffset: Math.max(0, totalRows - rows)
    readonly property var shownApps: results.slice(rowOffset * cols, (rowOffset + rows) * cols)
    // -1..1: the direction of the last step, easing back to 0 (tiles slide 12px and fade in from that side)
    property real stepShift: 0
    NumberAnimation {
        id: stepAnim
        target: root
        property: "stepShift"
        to: 0
        duration: 180
        easing.type: Easing.OutCubic
    }
    function scrollTo(offset) {
        const o = Math.max(0, Math.min(maxOffset, offset));
        if (o === rowOffset)
            return;
        stepShift = o > rowOffset ? 1 : -1;
        rowOffset = o;
        stepAnim.restart();
    }
    function select(i) {
        keyed = true;
        selected = Math.max(0, Math.min(results.length - 1, i));
        const r = Math.floor(selected / cols);
        if (r < rowOffset)
            scrollTo(r);
        else if (r >= rowOffset + rows)
            scrollTo(r - rows + 1);
    }
    readonly property int running: {
        const apps = new Set(KWin.windows.map(w => (w.app || "").toLowerCase()));
        return apps.size;
    }

    // motion state: p = drawer (fade + slide), tilesP = tiles over their sockets
    property real p: 0
    property real tilesP: 0
    function launch(e) {
        Apps.launch(e);
        Drawer.close();
    }

    visible: Drawer.open || p > 0.001
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
    // exclusive from the moment the surface maps (it only exists while open or fading out): flipping it on in the
    // same tick the window appears left KWin's keyboard focus on the window underneath
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    onVisibleChanged: if (visible) Qt.callLater(() => search.forceActiveFocus())

    mask: Region {
        item: Drawer.open ? catcher : null
    }
    // .glass backdrop-filter: blur(22px) - KWin's blur, behind the whole drawer rect in window coordinates (an
    // item-based region doesn't follow the scaled parent). Off while closed: a zero-size region trips KWin's GL.
    // Not translatable: saturate(1.2) (KWin's blur has no saturation) and the tiles' own 14px strength (KWin uses
    // one strength per screen) - tiles get the same blur through their holes in the glass.
    readonly property bool blurOn: root.p > 0.3 && root.width > 0
    BackgroundEffect.blurRegion: blurOn ? blurRect : null
    Region {
        id: blurRect
        x: Math.round((root.width - 980 * root.s) / 2)
        y: Math.round((root.height - 600 * root.s) / 2 + frame.y * root.s - frame.restY * root.s)
        width: Math.round(980 * root.s)
        height: Math.round(600 * root.s)
    }

    Connections {
        target: Drawer
        function onOpenChanged() {
            if (Drawer.open) {
                root.query = "";
                search.text = "";
                root.selected = 0;
                root.keyed = false;
                root.rowOffset = 0;
                openAnim.restart();
                search.forceActiveFocus();
            } else {
                openAnim.stop();
                closeAnim.restart();
            }
        }
    }
    SequentialAnimation {
        id: openAnim
        ScriptAction { script: { root.tilesP = 0; } }
        NumberAnimation { target: root; property: "p"; to: 1; duration: 500 } // linear clock; fade + SETTLE derive from it
        NumberAnimation { target: root; property: "tilesP"; to: 1; duration: 150 }
    }
    NumberAnimation {
        id: closeAnim
        target: root
        property: "p"
        to: 0
        duration: 280
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

        // moves and fades the drawer with its shadow. The mock's open frame (e = elapsed ms):
        //   opacity = clamp(e / 280), translateY = 60 * (1 - SETTLE(e / 500)), SETTLE = 1 - (1 - t)^4
        // close = opacity 1 -> 0 over 280ms linear, no movement (exits never move).
        Item {
            id: frame
            readonly property real restY: (parent.height - 600) / 2
            width: 980
            height: 600
            x: (parent.width - width) / 2
            y: restY + (Drawer.open ? 60 * Math.pow(1 - root.p, 4) : 0)
            opacity: Drawer.open ? Math.min(1, root.p * 500 / 280) : root.p

            // .drawer box-shadow: 0 20px 60px rgba(0,0,0,.45)
            RectangularShadow {
                anchors.fill: parent
                offset.y: 20
                blur: 60
                radius: 2
                color: Qt.rgba(0, 0, 0, 0.45)
            }
        }

        Item {
            id: drawer
            x: frame.x
            y: frame.y
            width: 980
            height: 600
            opacity: frame.opacity
            // .drawer border-radius 2px + overflow hidden
            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: drawerShape
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
            }

            MouseArea {
                anchors.fill: parent // swallow clicks inside the drawer
            }

            // .glass: linear-gradient(180deg, #fff 0%, #fff 16%, rgba(255,255,255,.7) 24%, rgba(230,232,238,.32) 40%,
            // rgba(40,42,48,.5) 100%), with a 6px-rounded hole cut under every tile (the mock's SVG mask)
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.00; color: "#FFFFFF" }
                    GradientStop { position: 0.16; color: "#FFFFFF" }
                    GradientStop { position: 0.24; color: Qt.rgba(1, 1, 1, 0.7) }
                    GradientStop { position: 0.40; color: Qt.rgba(230 / 255, 232 / 255, 238 / 255, 0.32) }
                    GradientStop { position: 1.00; color: Qt.rgba(40 / 255, 42 / 255, 48 / 255, 0.5) }
                }
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskInverted: true
                    maskSource: holes
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1.0
                }
            }
            Item {
                id: holes
                anchors.fill: parent
                visible: false
                layer.enabled: true
                Repeater {
                    model: root.cols * root.rows
                    Rectangle {
                        required property int index
                        x: grid.x + (index % root.cols) * 134
                        y: grid.y + Math.floor(index / root.cols) * 134
                        width: 120
                        height: 120
                        radius: 6
                        color: "white"
                    }
                }
            }

            // head
            Item {
                width: parent.width
                height: 64
                Text {
                    x: 24
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Applications"
                    color: "#111111"
                    font.family: Theme.body
                    font.weight: Font.DemiBold
                    font.pixelSize: 18
                    font.letterSpacing: Theme.em(18, 0.04)
                }
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 24
                    anchors.verticalCenter: parent.verticalCenter
                    text: Apps.all.length + " APPS · " + root.running + " RUNNING"
                    color: "#6c6f76"
                    font.family: Theme.mono
                    font.pixelSize: 12
                    font.letterSpacing: Theme.em(12, 0.14)
                }
                Rectangle {
                    x: 24
                    anchors.bottom: parent.bottom
                    width: parent.width - 48
                    height: 1
                    color: "#33363C"
                }
            }

            // grid: sockets everywhere, app tiles on top
            Grid {
                id: grid
                x: 24
                y: 64 + 22
                columns: root.cols
                spacing: 14
                Repeater {
                    model: root.cols * root.rows
                    Item {
                        id: cell
                        required property int index
                        readonly property var entry: root.shownApps[index] ?? null
                        width: 120
                        height: 120
                        // .tile.empty: the socket under every cell, fading out as the app tile fades in over it
                        TileFrame {
                            empty: true
                            opacity: cell.entry ? 1 - root.tilesP : 1
                        }
                        Loader {
                            active: !!cell.entry
                            opacity: root.tilesP * (1 - Math.abs(root.stepShift))
                            y: 12 * root.stepShift
                            sourceComponent: AppTile {
                                entry: cell.entry
                                selected: root.showSelection && root.rowOffset * root.cols + cell.index === root.selected
                                onActivated: root.launch(cell.entry)
                            }
                        }
                    }
                }
            }

            WheelHandler {
                property real acc: 0
                onWheel: event => {
                    acc += event.angleDelta.y;
                    while (Math.abs(acc) >= 120) {
                        root.scrollTo(root.rowOffset + (acc > 0 ? -1 : 1));
                        acc -= acc > 0 ? 120 : -120;
                    }
                }
            }
            // scroll indicator in the 18px right of the grid: a 2px track, the visible rows as a yellow thumb
            Item {
                visible: root.maxOffset > 0
                x: grid.x + grid.width + 8
                y: grid.y
                width: 2
                height: grid.height
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(1, 1, 1, 0.12)
                }
                Rectangle {
                    width: 2
                    height: parent.height * root.rows / Math.max(1, root.totalRows)
                    y: parent.height * root.rowOffset / Math.max(1, root.totalRows)
                    color: Theme.yellow
                    Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                }
            }

            // .search: 44px, 1px rgba(255,255,255,.22) border, 6px corners, rgba(20,21,24,.55),
            // inset 0 2px 8px rgba(0,0,0,.5); padding 0 16px, gap 12px; 13px mono .14em #8a8e96; b = #FFFA00 700 .1em
            Rectangle {
                id: searchBox
                x: 24
                width: parent.width - 48
                height: 44
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 22
                radius: 6
                color: Qt.rgba(20 / 255, 21 / 255, 24 / 255, 0.55)
                InsetShadow {
                    anchors.margins: 1 // inset shadows sit inside the border (padding box)
                    radius: 5
                    offsetY: 2
                    blur: 8
                    color: Qt.rgba(0, 0, 0, 0.5)
                }
                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.22)
                }
                Text {
                    id: prompt
                    x: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: "›››"
                    color: Theme.yellow
                    font.family: Theme.mono
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    font.letterSpacing: Theme.em(13, 0.1)
                }
                TextInput {
                    id: search
                    anchors.left: prompt.right
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    color: "#e8e9ec"
                    font.family: Theme.mono
                    font.pixelSize: 13
                    font.letterSpacing: Theme.em(13, 0.14)
                    selectionColor: Theme.yellow
                    selectedTextColor: Theme.plateInk
                    clip: true
                    onTextChanged: {
                        root.query = text;
                        root.selected = 0;
                        root.rowOffset = 0;
                    }
                    Keys.onEscapePressed: Drawer.close()
                    Keys.onReturnPressed: if (root.results[root.selected]) root.launch(root.results[root.selected])
                    Keys.onEnterPressed: if (root.results[root.selected]) root.launch(root.results[root.selected])
                    Keys.onLeftPressed: root.select(root.selected - 1)
                    Keys.onRightPressed: root.select(root.selected + 1)
                    Keys.onUpPressed: root.select(root.selected - root.cols)
                    Keys.onDownPressed: root.select(root.selected + root.cols)
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_PageDown) {
                            root.select(root.selected + root.rows * root.cols);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_PageUp) {
                            root.select(root.selected - root.rows * root.cols);
                            event.accepted = true;
                        }
                    }
                    Text {
                        visible: !search.text
                        anchors.verticalCenter: parent.verticalCenter
                        text: "SEARCH APPLICATIONS"
                        color: "#8a8e96"
                        font: search.font
                    }
                }
            }

            Item {
                id: drawerShape
                anchors.fill: parent
                visible: false
                layer.enabled: true
                Rectangle {
                    anchors.fill: parent
                    radius: 2
                    color: "white"
                }
            }
        }
    }
}
