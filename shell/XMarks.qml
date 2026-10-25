// Soft white X marks scattered around the art; the two big ones blurred for depth (Good Smile Racing fan art).
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes

Item {
    id: root

    // [x, y, size, stroke, blurred] in ground coordinates
    property var marks: [
        [1560, 300, 60, 22, false], [1610, 420, 40, 16, false], [1650, 520, 26, 11, false],
        [2560, 600, 50, 18, false], [2610, 700, 22, 9, false], [1980, 1180, 34, 12, false],
        [2470, 1150, 150, 60, true], [1480, 120, 110, 44, true]
    ]

    Repeater {
        model: root.marks
        Item {
            required property var modelData
            // padded so the round caps and the blur aren't cut off at the item's edge
            readonly property real pad: modelData[3] + (modelData[4] ? 40 : 0)
            x: modelData[0] - pad
            y: modelData[1] - pad
            width: modelData[2] + 2 * pad
            height: modelData[2] + 2 * pad
            layer.enabled: modelData[4]
            layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 32 }
            opacity: modelData[4] ? 0.7 : 1

            Shape {
                x: parent.pad
                y: parent.pad
                width: modelData[2]
                height: modelData[2]
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: GroundTheme.ink
                    strokeWidth: modelData[3]
                    capStyle: ShapePath.RoundCap
                    fillColor: "transparent"
                    PathMove { x: 0; y: 0 }
                    PathLine { x: modelData[2]; y: modelData[2] }
                    PathMove { x: modelData[2]; y: 0 }
                    PathLine { x: 0; y: modelData[2] }
                }
            }
        }
    }
}
