// The app drawer (ds-app-drawer): centred 980x600, solid white head fading into frosted glass, a grid of 120px
// sockets with app tiles on top, search at the bottom. Motion per the mock: open = fade 280ms + slide up 60px
// (500ms ease-out), then the tiles fade in over their sockets (150ms); close = fade in place (exits never move).
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    readonly property real s: Math.min(1, width / 1920, height / 1080)
    readonly property int cols: 7
    readonly property int rows: 3
    property string query: ""
    property int selected: 0
    readonly property var results: Apps.search(query)
    readonly property var shownApps: results.slice(0, cols * rows)
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
    WlrLayershell.keyboardFocus: Drawer.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    mask: Region {
        item: Drawer.open ? catcher : null
    }
    BackgroundEffect.blurRegion: Region {
        item: Drawer.open ? drawer : null
    }

    Connections {
        target: Drawer
        function onOpenChanged() {
            if (Drawer.open) {
                root.query = "";
                search.text = "";
                root.selected = 0;
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
        NumberAnimation { target: root; property: "p"; to: 1; duration: 500; easing.type: Easing.OutQuart }
        NumberAnimation { target: root; property: "tilesP"; to: 1; duration: 150; easing.type: Easing.OutCubic }
    }
    NumberAnimation {
        id: closeAnim
        target: root
        property: "p"
        to: 0
        duration: 280
        easing.type: Easing.OutCubic
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

        Item {
            id: drawer
            width: 980
            height: 600
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: Drawer.open ? 60 * (1 - root.p) : 0
            opacity: Drawer.open ? Math.min(1, root.p * 500 / 280) : root.p
            clip: true

            MouseArea {
                anchors.fill: parent // swallow clicks inside the drawer
            }

            // the glass: solid white head, fading to frosted dark
            Rectangle {
                anchors.fill: parent
                radius: 2
                gradient: Gradient {
                    GradientStop { position: 0.00; color: "#FFFFFF" }
                    GradientStop { position: 0.16; color: "#FFFFFF" }
                    GradientStop { position: 0.24; color: Qt.rgba(1, 1, 1, 0.7) }
                    GradientStop { position: 0.40; color: Qt.rgba(230 / 255, 232 / 255, 238 / 255, 0.32) }
                    GradientStop { position: 1.00; color: Qt.rgba(40 / 255, 42 / 255, 48 / 255, 0.5) }
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
                        // the empty socket (dot grid), fading out as the tile fades in
                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            color: Qt.rgba(70 / 255, 74 / 255, 82 / 255, 0.3)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.18)
                            opacity: cell.entry ? 1 - root.tilesP : 1
                            DotGrid {
                                anchors.fill: parent
                                anchors.margins: 2
                                pitch: 9
                                color: Qt.rgba(1, 1, 1, 0.16)
                            }
                        }
                        Loader {
                            active: !!cell.entry
                            opacity: root.tilesP
                            sourceComponent: AppTile {
                                entry: cell.entry
                                selected: cell.index === root.selected
                                onActivated: root.launch(cell.entry)
                            }
                        }
                    }
                }
            }

            // search (bottom)
            Rectangle {
                x: 24
                width: parent.width - 48
                height: 44
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 22
                radius: 6
                color: Qt.rgba(20 / 255, 21 / 255, 24 / 255, 0.55)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.22)
                Text {
                    id: prompt
                    x: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: "›››"
                    color: Theme.yellow
                    font.family: Theme.mono
                    font.weight: Font.Bold
                    font.pixelSize: 13
                }
                TextInput {
                    id: search
                    anchors.left: prompt.right
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.ink
                    font.family: Theme.mono
                    font.pixelSize: 13
                    font.letterSpacing: Theme.em(13, 0.1)
                    selectionColor: Theme.yellow
                    selectedTextColor: Theme.plateInk
                    clip: true
                    onTextChanged: {
                        root.query = text;
                        root.selected = 0;
                    }
                    Keys.onEscapePressed: Drawer.close()
                    Keys.onReturnPressed: if (root.shownApps[root.selected]) root.launch(root.shownApps[root.selected])
                    Keys.onEnterPressed: if (root.shownApps[root.selected]) root.launch(root.shownApps[root.selected])
                    Keys.onLeftPressed: root.selected = Math.max(0, root.selected - 1)
                    Keys.onRightPressed: root.selected = Math.min(root.shownApps.length - 1, root.selected + 1)
                    Keys.onUpPressed: root.selected = Math.max(0, root.selected - root.cols)
                    Keys.onDownPressed: root.selected = Math.min(root.shownApps.length - 1, root.selected + root.cols)
                    Text {
                        visible: !search.text
                        anchors.verticalCenter: parent.verticalCenter
                        text: "SEARCH APPLICATIONS"
                        color: "#8a8e96"
                        font: search.font
                    }
                }
            }
        }
    }
}
