// Panel header (the notifications mock's: TITLE tracked large, micro subline, a big count + label on the right).
import QtQuick

Item {
    id: root

    property string title: ""
    property string sub: ""
    property string count: ""
    property string countLabel: ""

    width: parent ? parent.width : 0
    implicitHeight: 64

    Column {
        x: 18
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        Text {
            text: root.title
            color: Theme.ink
            font.family: Theme.mono
            font.weight: Font.Bold
            font.pixelSize: 18
            font.letterSpacing: Theme.em(18, 0.3)
        }
        Micro {
            text: root.sub
        }
    }
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
        Text {
            anchors.baseline: parent.bottom
            text: root.count
            color: Theme.orange
            font.family: Theme.mono
            font.weight: Font.Bold
            font.pixelSize: 18
        }
        Micro {
            anchors.baseline: parent.bottom
            text: root.countLabel
        }
    }
}
