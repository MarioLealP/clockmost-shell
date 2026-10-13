// The mock's barcode strip: repeating 8px cell = bar 0-2, gap 2-4, bar 4-5, gap 5-8.
import QtQuick

Canvas {
    id: root

    property color color: Theme.ink

    onColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.fillStyle = root.color;
        for (let x = 0; x < width; x += 8) {
            ctx.fillRect(x, 0, Math.min(2, width - x), height);
            if (x + 4 < width)
                ctx.fillRect(x + 4, 0, 1, height);
        }
    }
}
