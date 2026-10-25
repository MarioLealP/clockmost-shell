// Home Assistant sections (the "Home" dashboard's own sections) with a live one-line summary each.
import QtQuick

Rectangle {
    id: root

    property var sections: HaSections.sections
    property string current: ""

    width: 354
    height: list.height + 12
    color: GroundTheme.bg // masks the line where it passes

    Column {
        id: list
        x: 12
        width: 330

        Item {
            width: parent.width
            height: 30
            Text { text: "HOME"; color: GroundTheme.ink2; font.family: GroundTheme.mono; font.pixelSize: 11; font.letterSpacing: 3 }
            Text { anchors.right: parent.right; text: HaClient.connected ? "HA DASHBOARD" : "HA OFFLINE"; color: GroundTheme.ink2; font.family: GroundTheme.mono; font.pixelSize: 9; font.letterSpacing: 2 }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 2; color: GroundTheme.ink }
        }

        Repeater {
            model: root.sections
            Rectangle {
                required property var modelData
                required property int index
                readonly property bool on: root.current === modelData.name
                width: list.width
                height: 41
                color: on ? GroundTheme.acc : "transparent"

                Text {
                    x: on ? 12 : 4
                    anchors.verticalCenter: parent.verticalCenter
                    text: String(index + 1).padStart(2, "0")
                    color: on ? GroundTheme.accInk : GroundTheme.ink2
                    font.family: GroundTheme.mono
                    font.pixelSize: 11
                }
                Text {
                    x: (on ? 12 : 4) + 30
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.name
                    color: on ? GroundTheme.accInk : GroundTheme.ink
                    font.family: GroundTheme.display
                    font.pixelSize: 22
                    font.weight: Font.ExtraBold
                    font.variableAxes: { "wdth": 75 }
                }
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.summary
                    color: on ? GroundTheme.accInk : GroundTheme.ink2
                    font.family: GroundTheme.mono
                    font.pixelSize: 11
                    font.letterSpacing: 2
                }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: GroundTheme.line }
            }
        }
    }
}
