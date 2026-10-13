// Side wings flanking the plate: micro print / barcode, a triangle marker pointing at the plate, a fading line.
// They shrink to fit `room`: the line shortens first (to 20px), then the print drops; when even the arrow and
// a 20px line don't fit, the wing fades out (nothing overlaps or gets cut) and fades back when there's room.
import QtQuick
import QtQuick.Shapes

Row {
    id: root

    property bool leftSide: true // the left wing points right (toward the plate)
    property string label: ""
    property real room: Infinity // width available between the widget group and the plate

    readonly property real lineNatural: leftSide ? 90 : 50
    readonly property real printWidth: leftSide ? micro.implicitWidth : 38
    readonly property real fixedWidth: 6 + spacing // arrow + gap
    readonly property bool showPrint: room >= printWidth + spacing + fixedWidth + 20
    readonly property real lineWidth: Math.max(20, Math.min(lineNatural, room - fixedWidth - (showPrint ? printWidth + spacing : 0)))
    readonly property bool fits: room >= fixedWidth + 20
    property real fitOpacity: fits ? 1 : 0
    Behavior on fitOpacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    spacing: 8
    layoutDirection: leftSide ? Qt.LeftToRight : Qt.RightToLeft

    Micro {
        id: micro
        visible: root.leftSide && root.showPrint
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
    }
    Barcode {
        visible: !root.leftSide && root.showPrint
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
        width: root.lineWidth
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: Qt.rgba(241 / 255, 241 / 255, 244 / 255, root.leftSide ? 0 : 0.3) }
            GradientStop { position: 1; color: Qt.rgba(241 / 255, 241 / 255, 244 / 255, root.leftSide ? 0.3 : 0) }
        }
    }
}
