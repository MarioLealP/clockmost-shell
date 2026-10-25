// .tgt: a quick-settings toggle. Olive slab + dot grid = on (like the active workspace), steel = off.
// Corner flag in the tile's colour, 2-digit index top-right.
import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property string icon: ""
    property string title: ""
    property string status: ""
    property string index: ""
    property color accent: Theme.ink2
    property bool on: false
    property bool available: true
    signal clicked

    implicitHeight: 62

    Rectangle {
        anchors.fill: parent
        color: root.on ? Qt.rgba(1, 95 / 255, 31 / 255, 0.34) : Qt.rgba(51 / 255, 54 / 255, 60 / 255, area.containsMouse && root.available ? 0.6 : 0.45)
        border.width: 1
        border.color: root.on ? Qt.rgba(1, 95 / 255, 31 / 255, 0.4) : Qt.rgba(1, 1, 1, 0.07)
        Behavior on color { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }

    // dot grid fading in from 45%
    Canvas {
        anchors.fill: parent
        opacity: root.on ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160 } }
        onWidthChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            for (let y = 3; y < height; y += 6)
                for (let x = 3; x < width; x += 6) {
                    const t = Math.max(0, (x / width - 0.45) / 0.55);
                    ctx.fillStyle = Qt.rgba(1, 95 / 255, 31 / 255, 0.3 * t);
                    ctx.beginPath();
                    ctx.arc(x, y, 1, 0, 2 * Math.PI);
                    ctx.fill();
                }
        }
    }

    // corner flag
    Shape {
        width: 10
        height: 10
        ShapePath {
            strokeWidth: 0
            fillColor: root.accent
            PathSvg { path: "M0 0H10L0 10z" }
        }
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: 8
        y: 6
        text: root.index
        color: root.on ? "#d8d36a" : "#43454c"
        font.family: Theme.mono
        font.pixelSize: 8
        font.letterSpacing: Theme.em(8, 0.1)
    }

    Row {
        x: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10
        Glyph {
            anchors.verticalCenter: parent.verticalCenter
            size: 20
            path: root.icon
            color: root.on ? root.accent : Theme.dim // mock colour pass: .tgt.on svg { color: var(--c) }
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            Text {
                text: root.title
                color: root.on ? "#fffbb0" : Theme.ink2
                font.family: Theme.mono
                font.weight: Font.Bold
                font.pixelSize: 11
                font.letterSpacing: Theme.em(11, 0.18)
            }
            Text {
                text: root.status
                color: root.on ? "#d8d36a" : Theme.faint
                font.family: Theme.mono
                font.pixelSize: 9
                font.letterSpacing: Theme.em(9, 0.18)
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.available
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
