// The autoscroll anchor marker on one screen: the phonograph's ring + chevrons (yellow dot, the active direction lit),
// where the middle button went down. Click-through overlay; only exists while autoscrolling.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    readonly property bool here: Autoscroll.active && screen
        && Autoscroll.x >= screen.x && Autoscroll.x < screen.x + screen.width
        && Autoscroll.y >= screen.y && Autoscroll.y < screen.y + screen.height

    visible: here
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "clockmost-autoscroll"
    WlrLayershell.layer: WlrLayer.Overlay
    mask: Region {}

    Canvas {
        id: mark
        width: 32
        height: 32
        x: Autoscroll.x - root.screen.x - 16
        y: Autoscroll.y - root.screen.y - 16
        property int dx: Autoscroll.dirX
        property int dy: Autoscroll.dirY
        onDxChanged: requestPaint()
        onDyChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.shadowColor = Qt.rgba(0, 0, 0, 0.6);
            ctx.shadowBlur = 6;
            ctx.fillStyle = Qt.rgba(12 / 255, 13 / 255, 15 / 255, 0.75);
            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.22);
            ctx.lineWidth = 1.6;
            ctx.beginPath();
            ctx.arc(16, 16, 13, 0, 2 * Math.PI);
            ctx.fill();
            ctx.stroke();
            ctx.shadowBlur = 0;
            const chev = (pts, lit) => {
                ctx.strokeStyle = lit ? Theme.yellow : Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.55);
                ctx.lineWidth = lit ? 2.2 : 1.6;
                ctx.beginPath();
                ctx.moveTo(pts[0], pts[1]);
                ctx.lineTo(pts[2], pts[3]);
                ctx.lineTo(pts[4], pts[5]);
                ctx.stroke();
            };
            chev([11, 11, 16, 6, 21, 11], dy < 0);
            chev([11, 21, 16, 26, 21, 21], dy > 0);
            chev([11, 11, 6, 16, 11, 21], dx < 0);
            chev([21, 11, 26, 16, 21, 21], dx > 0);
            ctx.fillStyle = Theme.yellow;
            ctx.beginPath();
            ctx.arc(16, 16, 2, 0, 2 * Math.PI);
            ctx.fill();
        }
    }
}
