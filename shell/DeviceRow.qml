// A selectable device line: yellow tick + bright name when it's the current one (the Dolphin-mock place style),
// a DEFAULT tag, micro detail on the second line. Click = make it current.
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

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(1, 1, 1, root.current ? 0.06 : area.containsMouse ? 0.035 : 0)
        Behavior on color { ColorAnimation { duration: 140 } }
    }
    Rectangle {
        width: 3
        height: parent.height
        color: Theme.yellow
        opacity: root.current ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 140 } }
    }
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
            color: root.current ? Theme.ink : Theme.ink2
            font.family: Theme.body
            font.pixelSize: 13
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
        color: Theme.yellow
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
