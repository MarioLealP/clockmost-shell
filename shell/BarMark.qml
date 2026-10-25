// CLOCKMOST mark (v2): an orange diamond + the name, on its own plate.
import QtQuick

Plate {
    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 13
            height: 13
            rotation: 45
            color: GroundTheme.acc
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "CLOCKMOST"
            color: GroundTheme.bg
            font.family: GroundTheme.mono
            font.weight: Font.Bold
            font.pixelSize: 12
            font.letterSpacing: 2
        }
    }
}
