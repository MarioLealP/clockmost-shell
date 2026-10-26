// ROOM: the bedroom as a technical floor plan; every node toggles its entity.
import QtQuick

Column {
    id: root

    spacing: 18

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
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: HaClient.toggle(node.entity) }
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

    Row {
        spacing: 6
        SecToggle { entity: "switch.extraplug"; label: "BATH PLUG  ·  " + (HaClient.st("sensor.extraplug_power") || "0") + " W" }
    }
}
