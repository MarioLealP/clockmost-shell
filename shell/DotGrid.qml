// Dot grid (CSS radial-gradient(c 1px, transparent) 0 0 / pitch pitch).
import QtQuick

Canvas {
    id: root

    property color color: Qt.rgba(0.067, 0.067, 0.067, 0.45)
    property real pitch: 6
    property real radius: 1

    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.fillStyle = root.color;
        for (let y = root.pitch / 2; y < height; y += root.pitch) {
            for (let x = root.pitch / 2; x < width; x += root.pitch) {
                ctx.beginPath();
                ctx.arc(x, y, root.radius, 0, 2 * Math.PI);
                ctx.fill();
            }
        }
    }
}
