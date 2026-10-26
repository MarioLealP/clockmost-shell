// ROOM: the bedroom as a technical floor plan. A light's dot toggles it, the wheel over a light sets its brightness, its
// name selects it for the strip below (brightness bar, warmth, colour - or ALL lights at once). The purifier: PM2.5 as
// the big number (click toggles), its modes as chips (auto / sleep / three speeds).
import QtQuick

Column {
    id: root

    spacing: 18

    readonly property var lights: ["light.chandelure", "light.yeelight_colorb_0x1b2f7704", "light.yeelight_colorb_0x1b1932dc",
        "light.yeelight_colorb_0x1b19e91f", "light.yeelight_colorb_0x1be53fa1"]
    property string sel: "light.chandelure" // or "ALL"
    readonly property var target: sel === "ALL" ? lights : sel
    readonly property string lead: sel === "ALL" ? lights[0] : sel // whose state the strip shows
    readonly property real level: HaClient.isOn(lead) ? (HaClient.attr(lead, "brightness") ?? 0) / 255 : 0

    function bright(entity, pct) {
        if (pct <= 0)
            HaClient.call("light", "turn_off", entity);
        else
            HaClient.call("light", "turn_on", entity, { brightness_pct: Math.round(pct) });
    }

    component Node: Item {
        id: node
        property string entity
        property string label
        property bool big: false
        property bool flip: false
        readonly property bool on: HaClient.isOn(entity)
        readonly property var rgb: HaClient.attr(entity, "rgb_color")
        readonly property color lit: rgb ? Qt.rgba(rgb[0] / 255, rgb[1] / 255, rgb[2] / 255, 1) : GroundTheme.acc
        width: 160
        height: big ? 40 : 24

        Rectangle {
            id: dot
            x: node.flip ? node.width - width : 0
            anchors.verticalCenter: parent.verticalCenter
            width: node.big ? 36 : 20
            height: width
            radius: width / 2
            color: node.on ? node.lit : GroundTheme.bg
            border.width: 1.5
            border.color: node.on ? node.lit : GroundTheme.ink
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            x: node.flip ? dot.x - width - 10 : dot.width + 10
            Text { anchors.right: node.flip ? parent.right : undefined; text: node.label; color: GroundTheme.ink; font.family: GroundTheme.mono; font.pixelSize: 11; font.letterSpacing: 2 }
            Text { anchors.right: node.flip ? parent.right : undefined; text: node.on ? "ON" : "OFF"; color: GroundTheme.ink2; font.family: GroundTheme.mono; font.pixelSize: 9; font.letterSpacing: 2 }
        }
        MouseArea { anchors.fill: dot; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: HaClient.toggle(node.entity) }
        MouseArea {
            x: node.flip ? 0 : dot.width + 4
            width: node.width - dot.width - 4
            height: node.height
            cursorShape: Qt.PointingHandCursor
            onClicked: root.sel = node.entity
        }
        WheelHandler {
            onWheel: event => {
                const now = HaClient.isOn(node.entity) ? (HaClient.attr(node.entity, "brightness") ?? 0) / 2.55 : 0;
                root.bright(node.entity, Math.max(0, Math.min(100, now + (event.angleDelta.y > 0 ? 10 : -10))));
            }
        }
        // selected: orange corner brackets around the node
        Repeater {
            model: root.sel === node.entity || (root.sel === "ALL" && root.lights.includes(node.entity)) ? 4 : 0
            Rectangle {
                required property int index
                x: (index % 2 ? node.width + 4 - width : -8)
                y: (index < 2 ? -6 : node.height + 6 - height)
                width: 8
                height: 8
                color: "transparent"
                border.width: 2
                border.color: GroundTheme.acc
            }
        }
    }

    SecHead {
        title: "ROOM"
        meta: HaSections.roomOn() + " / " + HaSections.room.length + " ON"
        onBack: HaSections.current = ""
    }

    Item {
        width: 560
        height: 330

        Rectangle { // the room outline + a faint 30px grid
            x: 20; y: 10; width: 440; height: 300
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(0.91, 0.9, 0.87, 0.35)
            Grid {
                anchors.fill: parent
                columns: 15
                Repeater { model: 150; Rectangle { width: 29.3; height: 30; color: "transparent"; border.width: 0.5; border.color: Qt.rgba(0.91, 0.9, 0.87, 0.04) } }
            }
        }
        Node { x: 40; y: 30; entity: "light.yeelight_colorb_0x1b2f7704"; label: "YL-1" }
        Node { x: 280; y: 30; entity: "light.yeelight_colorb_0x1b1932dc"; label: "YL-2"; flip: true }
        Node { x: 40; y: 250; entity: "light.yeelight_colorb_0x1b19e91f"; label: "YL-3" }
        Node { x: 280; y: 250; entity: "light.yeelight_colorb_0x1be53fa1"; label: "YL-4"; flip: true }
        Node { x: 170; y: 135; entity: "light.chandelure"; label: "CHANDELURE"; big: true }

        Rectangle { // the shelf strip along the bottom wall
            id: shelf
            x: 120; y: 296; width: 220; height: 8
            color: "transparent"
            Row {
                spacing: 4
                Repeater { model: 16; Rectangle { width: 10; height: 8; color: HaClient.isOn("light.shelf") ? GroundTheme.acc : GroundTheme.line } }
            }
            MouseArea { anchors.fill: parent; anchors.margins: -10; cursorShape: Qt.PointingHandCursor; onClicked: HaClient.toggle("light.shelf") }
        }
        Text { x: 120; y: 312; text: "SHELF  ·  " + (HaClient.st("sensor.shelf_power") || "--") + " W"; color: GroundTheme.ink2; font.family: GroundTheme.mono; font.pixelSize: 10; font.letterSpacing: 2 }

    }

    // the selected light (or ALL): brightness, warmth, colour
    Column {
        width: 560
        spacing: 10
        Item {
            width: 560
            height: 22
            Row {
                spacing: 6
                Repeater {
                    model: ["ALL"].concat(root.lights)
                    Rectangle {
                        required property string modelData
                        readonly property bool on: root.sel === modelData
                        width: lt.implicitWidth + 16
                        height: 22
                        color: on ? GroundTheme.acc : "transparent"
                        border.width: 1
                        border.color: on ? GroundTheme.acc : GroundTheme.line
                        Text {
                            id: lt
                            anchors.centerIn: parent
                            text: modelData === "ALL" ? "ALL" : modelData === "light.chandelure" ? "CHANDELURE" : "YL-" + (root.lights.indexOf(modelData))
                            color: parent.on ? GroundTheme.accInk : GroundTheme.ink2
                            font.family: GroundTheme.mono
                            font.pixelSize: 10
                            font.letterSpacing: 2
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.sel = parent.modelData }
                    }
                }
            }
        }
        // brightness: drag / click / wheel; sends on press and release (not every pixel)
        Item {
            id: bar
            width: 560
            height: 30
            property real shown: dragging ? dragValue : root.level
            property bool dragging: false
            property real dragValue: 0
            Text { anchors.verticalCenter: parent.verticalCenter; text: "BRIGHTNESS"; color: GroundTheme.ink2; font.family: GroundTheme.mono; font.pixelSize: 11; font.letterSpacing: 2 }
            Item {
                id: track
                x: 130
                width: 560 - 130 - 56
                height: parent.height
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 4
                    color: GroundTheme.line
                    Rectangle { width: parent.width * bar.shown; height: parent.height; color: GroundTheme.acc }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    function at(x) { return Math.max(0, Math.min(1, x / width)); }
                    onPressed: mouse => { bar.dragging = true; bar.dragValue = at(mouse.x); }
                    onPositionChanged: mouse => { if (pressed) bar.dragValue = at(mouse.x); }
                    onReleased: { root.bright(root.target, bar.dragValue * 100); bar.dragging = false; }
                    onWheel: wheel => root.bright(root.target, Math.max(0, Math.min(100, root.level * 100 + (wheel.angleDelta.y > 0 ? 10 : -10))))
                }
            }
            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(bar.shown * 100)
                color: GroundTheme.ink
                font.family: GroundTheme.display
                font.pixelSize: 22
                font.weight: Font.Black
                font.variableAxes: { "wdth": 70, "wght": 900 }
            }
        }
        // warmth chips + colour swatches
        Row {
            spacing: 6
            Repeater {
                model: [["WARM", 2700], ["NEUTRAL", 4000], ["COOL", 6500]]
                Rectangle {
                    required property var modelData
                    width: wt.implicitWidth + 18
                    height: 28
                    color: wm.containsMouse ? GroundTheme.ink : "transparent"
                    border.width: 1.5
                    border.color: GroundTheme.line
                    Text { id: wt; anchors.centerIn: parent; text: modelData[0]; color: wm.containsMouse ? GroundTheme.bg : GroundTheme.ink; font.family: GroundTheme.mono; font.pixelSize: 10; font.letterSpacing: 2 }
                    MouseArea { id: wm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: HaClient.call("light", "turn_on", root.target, { color_temp_kelvin: parent.modelData[1] }) }
                }
            }
            Item { width: 10; height: 1 }
            Repeater {
                model: [[255, 95, 31], [255, 30, 30], [255, 40, 160], [150, 60, 255], [40, 80, 255], [0, 200, 255], [40, 230, 90], [255, 210, 0]]
                Rectangle {
                    required property var modelData
                    width: 28
                    height: 28
                    color: Qt.rgba(modelData[0] / 255, modelData[1] / 255, modelData[2] / 255, 1)
                    border.width: sm.containsMouse ? 2 : 0
                    border.color: GroundTheme.ink
                    MouseArea { id: sm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: HaClient.call("light", "turn_on", root.target, { rgb_color: parent.modelData }) }
                }
            }
        }
    }

    Row { // the purifier, below the plan: its PM2.5 as the big number, click toggles it
            spacing: 10
            Text {
                text: String(HaClient.st("sensor.core_300s_series_pm2_5") || "--").padStart(2, "0")
                color: HaClient.isOn("fan.core_300s_series") ? GroundTheme.acc : GroundTheme.ink2
                font.family: GroundTheme.display
                font.pixelSize: 96
                font.weight: Font.Black
                font.variableAxes: { "wdth": 62, "wght": 900 }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: HaClient.toggle("fan.core_300s_series") }
            }
            Text {
                anchors.bottom: parent.bottom
                bottomPadding: 14
                text: "PM2.5\nPURIFIER  ·  " + (HaClient.isOn("fan.core_300s_series") ? "ON" : "OFF")
                color: GroundTheme.ink2
                font.family: GroundTheme.mono
                font.pixelSize: 10
                font.letterSpacing: 2
                lineHeight: 1.4
            }
        }

    // purifier modes: auto / sleep presets, three fan speeds
    Row {
        spacing: 6
        Repeater {
            model: [["AUTO", "auto"], ["SLEEP", "sleep"], ["LOW", 33], ["MID", 67], ["HIGH", 100]]
            Rectangle {
                required property var modelData
                readonly property var fan: "fan.core_300s_series"
                readonly property bool on: HaClient.isOn(fan) && (typeof modelData[1] === "string"
                    ? HaClient.attr(fan, "preset_mode") === modelData[1]
                    : !HaClient.attr(fan, "preset_mode") && Math.abs((HaClient.attr(fan, "percentage") ?? -100) - modelData[1]) < 10)
                width: pt.implicitWidth + 18
                height: 28
                color: on ? GroundTheme.ink : pm.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
                border.width: 1.5
                border.color: on ? GroundTheme.ink : GroundTheme.line
                Text { id: pt; anchors.centerIn: parent; text: parent.modelData[0]; color: parent.on ? GroundTheme.bg : GroundTheme.ink; font.family: GroundTheme.mono; font.pixelSize: 10; font.letterSpacing: 2 }
                MouseArea {
                    id: pm
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: typeof parent.modelData[1] === "string"
                        ? HaClient.call("fan", "set_preset_mode", parent.fan, { preset_mode: parent.modelData[1] })
                        : HaClient.call("fan", "set_percentage", parent.fan, { percentage: parent.modelData[1] })
                }
            }
        }
    }

    Row {
        spacing: 6
        SecToggle { entity: "switch.extraplug"; label: "BATH PLUG  ·  " + (HaClient.st("sensor.extraplug_power") || "0") + " W" }
    }
}
