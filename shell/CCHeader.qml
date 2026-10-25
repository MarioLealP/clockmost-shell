// Panel header (v2): the title big in Archivo like the ground's HA sections, a mono subline, the count as an orange
// chip on the right, a bone rule under it.
import QtQuick

Item {
    id: root

    property string title: ""
    property string sub: ""
    property string count: ""
    property string countLabel: ""

    width: parent ? parent.width : 0
    implicitHeight: 76

    Column {
        x: 18
        anchors.bottom: rule.top
        anchors.bottomMargin: 8
        spacing: 2
        Text {
            text: root.title
            color: Theme.ink
            font.family: GroundTheme.display
            font.weight: Font.Black
            font.variableAxes: { "wdth": 70 }
            font.pixelSize: 40
        }
        Text {
            text: root.sub
            color: Theme.dim
            font.family: Theme.mono
            font.pixelSize: 10
            font.letterSpacing: 2
        }
    }
    Rectangle {
        visible: root.count !== ""
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.bottom: rule.top
        anchors.bottomMargin: 12
        width: ct.implicitWidth + 16
        height: 22
        color: GroundTheme.acc
        Text {
            id: ct
            anchors.centerIn: parent
            text: (root.count + " " + root.countLabel).trim()
            color: GroundTheme.accInk
            font.family: Theme.mono
            font.pixelSize: 11
            font.letterSpacing: 2
        }
    }
    Rectangle {
        id: rule
        x: 18
        anchors.bottom: parent.bottom
        width: parent.width - 36
        height: 2
        color: Theme.ink
    }
}
