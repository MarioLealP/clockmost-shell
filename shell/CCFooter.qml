// Panel footer: hairline, barcode + CLOCKMOST · <code>, optional content on the right, dotted bottom edge.
import QtQuick

Item {
    id: root

    property string code: ""
    property string prefix: "CLOCKMOST · "
    default property alias actions: actionsRow.data

    width: parent ? parent.width : 0
    implicitHeight: 62

    Rectangle { width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.08) }
    Row {
        x: 18
        y: 12
        height: 32
        spacing: 10
        Barcode {
            anchors.verticalCenter: parent.verticalCenter
            width: 90
            height: 10
            color: Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.45)
        }
        Micro {
            anchors.verticalCenter: parent.verticalCenter
            text: root.prefix + root.code
        }
    }
    Row {
        id: actionsRow
        anchors.right: parent.right
        anchors.rightMargin: 18
        y: 12
        height: 32
        spacing: 6
    }
    DotGrid {
        x: 18
        y: parent.height - 11
        width: parent.width - 36
        height: 6
        pitch: 8
        color: Qt.rgba(1, 1, 1, 0.16)
    }
}
