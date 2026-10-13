// Diagonal hatch (CSS repeating-linear-gradient(135deg, c 0 line, transparent line pitch)).
import QtQuick

Canvas {
    id: root

    property color color: Qt.rgba(1, 1, 1, 0.055)
    property real line: 1
    property real pitch: 7

    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.strokeStyle = root.color;
        ctx.lineWidth = root.line;
        // 135deg stripes run bottom-left to top-right; the perpendicular pitch becomes pitch*sqrt(2) along x
        const step = root.pitch * Math.SQRT2;
        ctx.beginPath();
        for (let x = -height; x < width + height; x += step) {
            ctx.moveTo(x, height);
            ctx.lineTo(x + height, 0);
        }
        ctx.stroke();
    }
}
