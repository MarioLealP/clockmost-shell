// Felt's column: state, switches, her last line, the talk box (static for now; felt-core wiring is a later step).
import QtQuick

Rectangle {
    id: root

    property string state: "LISTENING"
    property string lastLine: "Shelf light's been on since noon. Want it off before the stream?"
    property string lastMeta: "18:41  ·  AMBIENT"

    width: 532
    height: col.height + 12
    color: GroundTheme.bg

    component Chip: Rectangle {
        property string label
        property bool on: false
        width: t.implicitWidth + 16
        height: 24
        color: "transparent"
        border.width: 1
        border.color: on ? GroundTheme.ink : GroundTheme.line
        Text { id: t; anchors.centerIn: parent; text: parent.label; color: parent.on ? GroundTheme.ink : GroundTheme.ink2; font.family: GroundTheme.mono; font.pixelSize: 10; font.letterSpacing: 2 }
    }

    Column {
        id: col
        x: 12
        width: 520
        spacing: 0

        Item {
            width: parent.width
            height: 66
            Text {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10
                text: "FELT"
                color: GroundTheme.ink
                font.family: GroundTheme.display
                font.pixelSize: 64
                font.weight: Font.Black
                font.variableAxes: { "wdth": 70 }
            }
            Row {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 16
                spacing: 8
                Rectangle { width: 10; height: 10; radius: 5; color: GroundTheme.acc; anchors.verticalCenter: parent.verticalCenter }
                Text { text: root.state; color: GroundTheme.acc; font.family: GroundTheme.mono; font.pixelSize: 11; font.letterSpacing: 3 }
            }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 2; color: GroundTheme.ink }
        }

        Item { width: 1; height: 12 }
        Item {
            width: parent.width
            height: 24
            Row { spacing: 6; Chip { label: "QUIET"; on: true } Chip { label: "HIDDEN"; on: true } Chip { label: "DJ" } }
            Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: "BONSAI 27B  ·  IDLE"; color: GroundTheme.ink2; font.family: GroundTheme.mono; font.pixelSize: 10; font.letterSpacing: 2 }
        }

        Item { width: 1; height: 26 }
        Item {
            width: parent.width
            height: quote.height
            Rectangle { width: 4; height: parent.height; color: GroundTheme.acc }
            Column {
                id: quote
                x: 22
                width: parent.width - 22
                spacing: 12
                Text {
                    width: parent.width
                    text: root.lastLine
                    wrapMode: Text.WordWrap
                    color: GroundTheme.ink
                    font.family: GroundTheme.display
                    font.pixelSize: 30
                    font.weight: Font.DemiBold
                    lineHeight: 1.18
                }
                Text { text: root.lastMeta; color: GroundTheme.ink2; font.family: GroundTheme.mono; font.pixelSize: 10; font.letterSpacing: 3 }
            }
        }

        Item { width: 1; height: 22 }
        Rectangle {
            width: parent.width
            height: 48
            color: "transparent"
            border.width: 1.5
            border.color: GroundTheme.ink
            Row {
                x: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                Text { text: "SAY SOMETHING"; color: GroundTheme.ink2; font.family: GroundTheme.mono; font.pixelSize: 12; font.letterSpacing: 3; anchors.verticalCenter: parent.verticalCenter }
                Rectangle { width: 9; height: 18; color: GroundTheme.acc; anchors.verticalCenter: parent.verticalCenter }
            }
            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                width: kbd.implicitWidth + 12
                height: 20
                color: GroundTheme.ink
                Text { id: kbd; anchors.centerIn: parent; text: "META+F"; color: GroundTheme.bg; font.family: GroundTheme.mono; font.pixelSize: 10 }
            }
        }
    }
}
