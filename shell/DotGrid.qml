// Dot grid (CSS radial-gradient(c 1px, transparent) 0 0 / pitch pitch), centred: the leftover of width % pitch is
// split between both sides (3440 = 143 x 24 + 8), so things can sit on dots symmetrically. dot(i, len) and snap(v,
// len) give the dot positions for the rest of the ground to align to.
import QtQuick

Canvas {
    id: root

    property color color: Qt.rgba(0.067, 0.067, 0.067, 0.45)
    property real pitch: 6
    property real radius: 1
    readonly property real offX: (width % pitch) / 2 + pitch / 2
    readonly property real offY: (height % pitch) / 2 + pitch / 2

    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.fillStyle = root.color;
        for (let y = root.offY; y < height; y += root.pitch) {
            for (let x = root.offX; x < width; x += root.pitch) {
                ctx.beginPath();
                ctx.arc(x, y, root.radius, 0, 2 * Math.PI);
                ctx.fill();
            }
        }
    }
}
