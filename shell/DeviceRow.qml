// A selectable device line (v2): name + detail, the current one tagged DEFAULT in orange. Click = make it current.
import QtQuick

Item {
    id: root

    property string name: ""
    property string detail: ""
    property bool current: false
    property string tag: "DEFAULT"
    signal clicked

    width: parent ? parent.width : 0
    implicitHeight: 40

    // v2: hover wash + a hairline under each row; the current one is marked by its orange tag only
    Rectangle {
        anchors.fill: parent
        color: area.containsMouse && !root.current ? Qt.rgba(1, 1, 1, 0.04) : "transparent"
    }
    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: GroundTheme.line }
    Column {
        // both edges anchored: with only a right anchor the width is implicit, and the children's
        // width: parent.width makes that 0 (names never drew)
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.right: tagBox.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3
        Text {
            width: parent.width
            elide: Text.ElideRight
            text: root.name
            color: root.current ? Theme.ink : Theme.dim
            font.family: Theme.body
            font.pixelSize: 14
        }
        Micro {
            width: parent.width
            elide: Text.ElideRight
            text: root.detail
        }
    }
    Rectangle {
        id: tagBox
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        visible: root.current
        width: tagText.implicitWidth + 12
        height: 16
        color: GroundTheme.acc
        Text {
            id: tagText
            anchors.centerIn: parent
            text: root.tag
            color: Theme.plateInk
            font.family: Theme.mono
            font.weight: Font.Bold
            font.pixelSize: 8
            font.letterSpacing: Theme.em(8, 0.18)
        }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.current ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
