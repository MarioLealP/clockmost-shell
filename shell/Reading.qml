// One row of the system readout: LABEL, the big number + unit, a note on the right (temperature / total), a thin bar
// that eases to the level. hot = the note turns orange.
import QtQuick

Item {
    id: root

    property string label
    property var value
    property string unit
    property string note
    property real level: 0
    property bool hot: false

    width: parent ? parent.width : 360
    height: 66

    Text { y: 4; text: root.label; color: GroundTheme.ink2; font.family: GroundTheme.mono; font.pixelSize: 11; font.letterSpacing: 3 }
    Row {
        y: 18
        spacing: 4
        Text {
            text: root.value
            color: GroundTheme.ink
            font.family: GroundTheme.display
            font.pixelSize: 40
            font.weight: Font.Black
            font.variableAxes: { "wdth": 70, "wght": 900 }
            lineHeightMode: Text.FixedHeight
            lineHeight: 40
        }
        Text {
            anchors.bottom: parent.bottom
            bottomPadding: 4
            text: root.unit
            color: GroundTheme.ink2
            font.family: GroundTheme.display
            font.pixelSize: 15
            font.weight: Font.Black
            font.variableAxes: { "wght": 900 }
        }
    }
    Text {
        anchors.right: parent.right
        y: 4
        text: root.note
        color: root.hot ? GroundTheme.acc : GroundTheme.ink2
        font.family: GroundTheme.mono
        font.pixelSize: 11
        font.letterSpacing: 2
    }
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 4
        color: GroundTheme.line
        Rectangle {
            height: parent.height
            width: parent.width * Math.max(0, Math.min(1, root.level))
            color: GroundTheme.acc
            Behavior on width { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
        }
    }
}
