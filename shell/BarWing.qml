// Side wings flanking the plate: micro print / barcode, a triangle marker pointing at the plate, a fading line.
import QtQuick
import QtQuick.Shapes

Row {
    id: root

    property bool leftSide: true // the left wing points right (toward the plate)
    property string label: ""

    spacing: 8
    layoutDirection: leftSide ? Qt.LeftToRight : Qt.RightToLeft

    Micro {
        visible: root.leftSide
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
    }
    Barcode {
        visible: !root.leftSide
        anchors.verticalCenter: parent.verticalCenter
        width: 38
        height: 8
        color: Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.45)
    }

    Shape {
        anchors.verticalCenter: parent.verticalCenter
        width: 6
        height: 8
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: 0
            fillColor: Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.5)
            startX: root.leftSide ? 0 : 6
            startY: 0
            PathLine { x: root.leftSide ? 6 : 0; y: 4 }
            PathLine { x: root.leftSide ? 0 : 6; y: 8 }
        }
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: root.leftSide ? 90 : 50
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.rgba(241 / 255, 241 / 255, 244 / 255, root.leftSide ? 0 : 0.3) }
            GradientStop { position: 1; color: Qt.rgba(241 / 255, 241 / 255, 244 / 255, root.leftSide ? 0.3 : 0) }
        }
    }
}
