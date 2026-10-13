// .lbl: LABEL ———————— micro   (a section heading inside a panel)
import QtQuick

Item {
    id: root

    property string text: ""
    property string note: ""

    implicitHeight: 14
    width: parent ? parent.width : 0

    Text {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        color: Theme.dim
        font.family: Theme.mono
        font.weight: Font.Bold
        font.pixelSize: 10
        font.letterSpacing: Theme.em(10, 0.2)
    }
    Rectangle {
        anchors.left: label.right
        anchors.leftMargin: 8
        anchors.right: noteText.left
        anchors.rightMargin: root.note ? 8 : 0
        anchors.verticalCenter: parent.verticalCenter
        height: 1
        color: Qt.rgba(1, 1, 1, 0.08)
    }
    Micro {
        id: noteText
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.note
    }
}
