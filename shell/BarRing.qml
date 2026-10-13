// L3 crosshair ring behind the clock, centred on the top edge: r150 solid, r128 dashed, vertical hairline.
import QtQuick

Canvas {
    id: root

    width: 300
    height: 162 // lower half of the ring + the hairline's 12px overhang

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        const cx = width / 2;
        ctx.lineWidth = 1;

        ctx.strokeStyle = Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.10);
        ctx.beginPath();
        ctx.arc(cx, 0, 149.5, 0, Math.PI);
        ctx.stroke();

        ctx.strokeStyle = Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.07);
        ctx.setLineDash([3, 3]);
        ctx.beginPath();
        ctx.arc(cx, 0, 127.5, 0, Math.PI);
        ctx.stroke();
        ctx.setLineDash([]);

        ctx.fillStyle = Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.08);
        ctx.fillRect(Math.floor(cx), 0, 1, height);
    }
}
