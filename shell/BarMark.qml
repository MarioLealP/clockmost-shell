// CLOCKMOST mark: name + barcode + host line, divider on the right.
import QtQuick

Item {
    id: root

    implicitWidth: col.implicitWidth + 14
    implicitHeight: col.implicitHeight

    Column {
        id: col
        spacing: 3
        Text {
            text: "CLOCKMOST"
            color: Theme.ink
            font.family: Theme.mono
            font.weight: Font.Bold
            font.pixelSize: 12
            font.letterSpacing: Theme.em(12, 0.32)
        }
        Row {
            spacing: 6
            Barcode {
                anchors.verticalCenter: parent.verticalCenter
                width: 46
                height: 6
                color: Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.55)
            }
            Micro {
                anchors.verticalCenter: parent.verticalCenter
                text: "DT-01 · CACHYOS"
            }
        }
    }

    Rectangle {
        anchors.right: parent.right
        width: 1
        height: parent.height
        color: Qt.rgba(1, 1, 1, 0.10)
    }
}
