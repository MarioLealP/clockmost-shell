// .felt: Felt's dedicated button - magenta glyph block + name + status line. Static until Felt runs here.
import QtQuick
import QtQuick.Shapes

Rectangle {
    id: root

    property string status: "VISIBLE · LOCAL"
    property color statusColor: Theme.green

    implicitWidth: row.implicitWidth + 12
    implicitHeight: 38
    color: Qt.rgba(12 / 255, 13 / 255, 15 / 255, 0.7)
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.10)

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Rectangle {
            width: 38
            height: 38
            color: Theme.magenta

            // the mock's Felt glyph (24-unit viewBox) at 22px, stroke 2.2, square caps
            Shape {
                anchors.centerIn: parent
                width: 24
                height: 24
                scale: 22 / 24
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: Theme.plateInk
                    strokeWidth: 2.2
                    fillColor: "transparent"
                    capStyle: ShapePath.SquareCap
                    PathSvg { path: "M5 20v-2a7 7 0 0 1 14 0v2 M8 8a4 4 0 1 0 8 0a4 4 0 1 0 -8 0 M9 3l1.5 2 M15 3l-1.5 2" }
                }
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            Text {
                text: "FELT"
                color: Theme.ink
                font.family: Theme.mono
                font.weight: Font.Bold
                font.pixelSize: 11
                font.letterSpacing: Theme.em(11, 0.26)
            }
            Text {
                text: "● " + root.status
                color: root.statusColor
                font.family: Theme.mono
                font.pixelSize: 8
                font.letterSpacing: Theme.em(8, 0.18)
            }
        }
    }
}
