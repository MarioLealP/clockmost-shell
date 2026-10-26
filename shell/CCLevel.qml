// A volume level (v2). compact = LABEL | thin bar | number on one row; else LABEL + big number over the bar.
// Drag / click on the bar sets it, the wheel nudges 5%, clicking the label toggles mute.
import QtQuick

Item {
    id: root

    property string label
    property real value: 0
    property bool muted: false
    property bool compact: false
    signal changed(real v)
    signal labelClicked

    width: parent ? parent.width : 0
    height: compact ? 34 : 66

    Text {
        id: lbl
        y: root.compact ? (root.height - height) / 2 : root.height - 26 - height
        width: root.compact ? 150 : parent.width - num.width - 8
        elide: Text.ElideRight
        text: root.label + (root.muted ? "  ·  MUTED" : "")
        color: root.muted ? Theme.dim : (root.compact ? Theme.ink : Theme.dim)
        font.family: Theme.mono
        font.pixelSize: root.compact ? 11 : 10
        font.letterSpacing: 2
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.labelClicked() }
    }
    Text {
        id: num
        anchors.right: parent.right
        y: root.compact ? (root.height - height) / 2 : 0
        text: Math.round(root.value * 100)
        color: root.muted ? Theme.dim : Theme.ink
        font.family: GroundTheme.display
        font.weight: Font.Black
        font.variableAxes: { "wdth": 70, "wght": 900 }
        font.pixelSize: root.compact ? 16 : 44
    }
    Item {
        id: track
        x: root.compact ? 160 : 0
        width: root.compact ? parent.width - 160 - 48 : parent.width
        height: 16
        y: root.compact ? (root.height - height) / 2 : root.height - 16
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 4
            color: GroundTheme.lineSolid
            Rectangle { width: parent.width * Math.max(0, Math.min(1, root.value)); height: parent.height; color: root.muted ? Theme.faint : GroundTheme.acc }
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            function set(x) { root.changed(Math.max(0, Math.min(1, x / width))); }
            onPressed: mouse => set(mouse.x)
            onPositionChanged: mouse => { if (pressed) set(mouse.x); }
            onWheel: wheel => root.changed(Math.max(0, Math.min(1, root.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
        }
    }
    Rectangle { visible: root.compact; anchors.bottom: parent.bottom; width: parent.width; height: 1; color: GroundTheme.lineSolid }
}
