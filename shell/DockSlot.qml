// One dock app slot = ds-dock-v2's .slot, rule by rule (after its colour pass):
//   .tile       56px square, 1px rgba(255,255,255,.10) border, inset 0 2px 10px rgba(0,0,0,.55),
//               background linear-gradient(180deg, rgba(58,62,70,.5) 25%, mix(c 42%, rgba(30,32,37,.6)) 100%)
//   .topo       cover, opacity .35
//   .lg / .lt   28px icon / 700 20px letter in c, centred at top 44% (real icons stay in their own colours)
//   ::before    12px corner cut, top-left, c
//   .cd         7px mono .12em at left 4 / bottom 6, mix(c 70%, #fff) at .7
//   .ub         3px underbar, c
//   .wb2        a 8x3 bar per window, 3px apart, 5px under the tile, c
//   .focus      tile + bars lifted 10px, 2px yellow border, yellow underbar + bars, drop 0 8px 20px rgba(0,0,0,.5),
//               yellow 8x6 pointer above
//   .notif.pin  the orange diamond at the tile's top-right (window wants attention / unread notifications)
//   .tip        hover label above the slot (DockTip)
// Not in the mock: right click = the dock menu (DockMenuWindow); a pinned slot drags sideways to reorder (DockWindow
// owns the drag: `shift` is this slot's sideways offset - the pointer for the dragged one, a slot pitch for the ones
// making room).
import QtQuick
import QtQuick.Effects // RectangularShadow
import Quickshell

Item {
    id: root

    required property var slot
    readonly property color c: AppColors.of(slot.app)
    readonly property bool focused: slot.active
    readonly property bool allMinimized: slot.windows.length > 0 && slot.windows.every(w => w.minimized)
    readonly property alias hovered: area.containsMouse
    // the app's own icon in true colour (Mario: no tinting); curated marks where we have one (the mock's firefox.svg)
    readonly property string curated: ({ "firefox": Qt.resolvedUrl("assets/logo-firefox.svg") })[slot.key.toLowerCase()] ?? ""
    readonly property string icon: curated || (slot.entry ? Quickshell.iconPath(slot.entry.icon || "", true) : "")
    readonly property bool alert: slot.windows.some(w => w.attention)
        || Notifs.records.some(r => !r.read && slot.entry && (r.n.appName || "").toLowerCase() === slot.entry.name.toLowerCase())

    function mix(a, b, t) {
        return Qt.rgba(a.r * t + b.r * (1 - t), a.g * t + b.g * (1 - t), a.b * t + b.b * (1 - t), a.a * t + b.a * (1 - t));
    }

    width: 56
    height: 56 + 5 + 3

    property real shift: 0
    property bool dragging: false
    signal dragStarted
    signal dragMoved(real dx) // pointer travel since the press, in dock units
    signal dragEnded
    transform: Translate {
        x: root.shift
    }
    Behavior on shift {
        enabled: !root.dragging
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    property real lift: 0 // v2: no focus lift (motionless build) - the focused tile is orange instead

    Item {
        id: body
        width: parent.width
        height: parent.height
        y: -10 * root.lift

        // focus drop shadow 0 8px 20px rgba(0,0,0,.5)
        RectangularShadow {
            x: 0
            y: 0
            width: 56
            height: 56
            offset.y: 8
            blur: 20
            color: Qt.rgba(0, 0, 0, 0.5)
            opacity: root.lift
        }

        Item {
            id: tile
            width: 56
            height: 56
            clip: true
            // every window minimized: the tile steps back
            opacity: root.allMinimized ? 0.45 : 1
            Behavior on opacity { NumberAnimation { duration: 180 } }

            // v2: a dark tile on the bone plate; the focused app's tile is the orange one
            Rectangle {
                anchors.fill: parent
                color: root.focused ? GroundTheme.acc : GroundTheme.bg
            }

            Image {
                id: logo
                visible: root.icon !== ""
                x: (parent.width - width) / 2
                y: parent.height * 0.44 - height / 2
                width: 28
                height: 28
                source: root.icon
                sourceSize.width: 64
                sourceSize.height: 64
                smooth: true
            }
            Text {
                visible: root.icon === ""
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.44 - height / 2
                text: root.slot.name.charAt(0).toUpperCase()
                color: root.c
                font.family: Theme.body
                font.weight: Font.Bold
                font.pixelSize: 20
            }

            Text {
                x: 4
                y: 3
                text: DockApps.code(root.slot)
                color: root.focused ? GroundTheme.accInk : GroundTheme.ink2
                font.family: GroundTheme.mono
                font.pixelSize: 7
                font.letterSpacing: 1
            }
        }

        AttentionPin {
            visible: root.alert
            anchors.top: tile.top
            anchors.right: tile.right
        }

        // focus pointer: border-top 6px yellow, 4px sides -> an 8x6 down triangle, 13px above the lifted tile
        Canvas {
            visible: root.lift > 0.01
            opacity: root.lift
            x: (56 - 8) / 2
            y: -9
            width: 8
            height: 6
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                ctx.fillStyle = Theme.yellow;
                ctx.beginPath();
                ctx.moveTo(0, 0);
                ctx.lineTo(8, 0);
                ctx.lineTo(4, 6);
                ctx.closePath();
                ctx.fill();
            }
        }

        // window-count bars: one per window - full 3px bar = on screen, flat 1px line at half strength = minimized
        // (Mario: minimized and unfocused looked the same; not in the mock. A hollow 3px bar read as solid.)
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 56 + 5
            spacing: 3
            Repeater {
                model: root.slot.windows.slice(0, 5)
                Item {
                    required property var modelData
                    width: 8
                    height: 3
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: 8
                        height: modelData.minimized ? 1 : 3
                        opacity: modelData.minimized ? 0.5 : 1
                        color: root.focused && !modelData.minimized ? GroundTheme.acc : GroundTheme.bg
                    }
                }
            }
        }
    }

    DockTip {
        z: 10
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height - 82 - height // CSS bottom: 82px from the slot's bottom
        // apps with windows get the window preview panel instead (DockPreview)
        opacity: root.hovered && !root.slot.windows.length && !root.dragging && !DockMenu.open ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 140 } }
        title: root.slot.name
        sub: {
            const ws = root.slot.windows;
            if (!ws.length)
                return root.slot.pinned ? "PINNED" : "";
            const t = (ws.find(w => w.active) ?? ws[0]).title;
            return ws.length + (ws.length === 1 ? " WINDOW · " : " WINDOWS · ") + (t.length > 28 ? t.slice(0, 27) + "…" : t);
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        cursorShape: root.dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
        // drag: window x of the press, in dock units (the slot itself moves while dragged, so not local x)
        property real pressX: 0
        property bool dragged: false
        readonly property real unit: Math.min(1, (QsWindow.window?.width ?? 1920) / 1920)
        function windowX(mouse) {
            return area.mapToItem(null, mouse.x, 0).x / unit;
        }
        onPressed: mouse => {
            pressX = windowX(mouse);
            dragged = false;
        }
        onPositionChanged: mouse => {
            if (!(pressedButtons & Qt.LeftButton) || !root.slot.pinned)
                return;
            const dx = windowX(mouse) - pressX;
            if (!dragged && Math.abs(dx) > 8) {
                dragged = true;
                root.dragStarted();
            }
            if (dragged)
                root.dragMoved(dx);
        }
        onReleased: if (dragged) root.dragEnded()
        onClicked: mouse => {
            if (dragged)
                return;
            if (mouse.button === Qt.LeftButton)
                DockApps.activate(root.slot);
            else if (mouse.button === Qt.MiddleButton)
                DockApps.launch(root.slot);
            else
                DockMenu.show(root.slot, QsWindow.window?.screen?.name ?? "", area.mapToItem(null, area.width / 2, 0).x);
        }
    }
}
