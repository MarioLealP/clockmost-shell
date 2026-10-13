// A line icon from the mocks: an SVG path in a 24-unit viewBox, stroked with square caps (no fill).
import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property string path: ""
    property color color: Theme.ink2
    property real size: 18
    property real stroke: 2

    width: size
    height: size

    Shape {
        width: 24
        height: 24
        scale: root.size / 24
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: root.color
            strokeWidth: root.stroke * 24 / root.size // keep the stroke in screen px after scaling
            fillColor: "transparent"
            capStyle: ShapePath.SquareCap
            joinStyle: ShapePath.MiterJoin
            PathSvg { path: root.path }
        }
    }
}
