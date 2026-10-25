// A tab's lead (v2): one poster-sized value, a mono subline, a bone rule; optional thin orange bar (0..1, < 0 = none).
import QtQuick

Column {
    id: root

    property string value: ""
    property string unit: ""
    property string sub: ""
    property real bar: -1
    property int size: 150

    width: parent ? parent.width : 0
    spacing: 0

    Row {
        spacing: 4
        Text {
            text: root.value
            color: Theme.ink
            font.family: GroundTheme.display
            font.weight: Font.Black
            font.variableAxes: { "wdth": 68 }
            font.pixelSize: root.size
            lineHeightMode: Text.FixedHeight
            lineHeight: root.size * 0.84
        }
        Text {
            visible: root.unit !== ""
            anchors.bottom: parent.bottom
            text: root.unit
            color: Theme.dim
            font.family: GroundTheme.display
            font.weight: Font.Black
            font.pixelSize: root.size * 0.32
        }
    }
    Text {
        topPadding: 10
        bottomPadding: 14
        width: parent.width
        elide: Text.ElideRight
        text: root.sub
        color: Theme.dim
        font.family: Theme.mono
        font.pixelSize: 11
        font.letterSpacing: 2
    }
    Rectangle {
        visible: root.bar >= 0
        width: parent.width
        height: 4
        color: GroundTheme.line
        Rectangle { width: parent.width * Math.max(0, Math.min(1, root.bar)); height: parent.height; color: GroundTheme.acc }
    }
    Item { visible: root.bar >= 0; width: 1; height: 12 }
    Rectangle { width: parent.width; height: 2; color: Theme.ink }
    Item { width: 1; height: 12 }
}
