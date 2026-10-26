// Panel footer (v2): hairline, CLOCKMOST · <code> in small mono, optional buttons on the right.
import QtQuick

Item {
    id: root

    property string code: ""
    property string prefix: "CLOCKMOST · "
    default property alias actions: actionsRow.data

    width: parent ? parent.width : 0
    implicitHeight: 66

    Rectangle { width: parent.width; height: 1; color: GroundTheme.lineSolid }
    Text {
        x: 22
        y: 12
        height: 32
        verticalAlignment: Text.AlignVCenter
        text: root.prefix + root.code
        color: Theme.dim
        font.family: Theme.mono
        font.pixelSize: 9
        font.letterSpacing: 2
    }
    Row {
        id: actionsRow
        anchors.right: parent.right
        anchors.rightMargin: 22
        y: 12
        height: 32
        spacing: 6
    }
}
