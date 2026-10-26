// Level row (v2): outlined icon | NAME over a thin bar with an orange fill | the number.
// Click/drag on the bar sets the level; the wheel nudges it 5%.
import QtQuick

Item {
    id: root

    property string icon: ""
    property color accent: Theme.cyan
    property string name: ""
    property real value: 0 // 0..1
    property bool muted: false
    readonly property int segments: 24
    signal changed(real v)
    signal iconClicked

    implicitHeight: 30

    Rectangle {
        id: badge
        anchors.verticalCenter: parent.verticalCenter
        width: 26
        height: 26
        color: "transparent"
        border.width: 1
        border.color: GroundTheme.line
        Glyph {
            anchors.centerIn: parent
            size: 16
            path: root.icon
            color: root.muted ? Theme.dim : Theme.ink
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.iconClicked()
        }
    }

    Column {
        anchors.left: badge.right
        anchors.leftMargin: 12
        anchors.right: number.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5

        Text {
            width: parent.width
            elide: Text.ElideRight
            text: root.name
            color: Theme.dim
            font.family: Theme.mono
            font.pixelSize: 9
            font.letterSpacing: Theme.em(9, 0.2)
        }
        Item {
            width: parent.width
            height: 8
            // v2: a thin track with an orange fill (the segmented blocks were Endfield)
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 4
                color: GroundTheme.line
                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, root.value))
                    height: parent.height
                    color: root.muted ? Theme.faint : GroundTheme.acc
                }
            }
            // input sits beside the Row, not in it (a Row lays out every child)
            MouseArea {
                anchors.fill: parent
                anchors.topMargin: -6
                anchors.bottomMargin: -6
                cursorShape: Qt.PointingHandCursor
                function set(x) { root.changed(Math.max(0, Math.min(1, x / width))); }
                onPressed: mouse => set(mouse.x)
                onPositionChanged: mouse => { if (pressed) set(mouse.x); }
                onWheel: wheel => root.changed(Math.max(0, Math.min(1, root.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
            }
        }
    }

    Text {
        id: number
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 40
        horizontalAlignment: Text.AlignRight
        text: Math.round(root.value * 100)
        color: root.muted ? Theme.dim : Theme.ink
        font.family: GroundTheme.display
        font.weight: Font.Black
        font.variableAxes: { "wght": 900 }
        font.pixelSize: 18
        font.letterSpacing: Theme.em(16, 0.06)
    }
}
