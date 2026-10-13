// L1 band: dark frost + diagonal hatch fading toward the centre; L2 bottom edge: hairline + tick ruler.
import QtQuick

Item {
    id: root

    height: Theme.band

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(30 / 255, 31 / 255, 36 / 255, 0.92) }
            GradientStop { position: 1; color: Qt.rgba(16 / 255, 17 / 255, 20 / 255, 0.88) }
        }
    }

    Hatch {
        anchors.fill: parent
    }

    // hatch mask: strong at the sides, calm in the middle where the clock hangs
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.00; color: Qt.rgba(16 / 255, 17 / 255, 20 / 255, 0) }
            GradientStop { position: 0.34; color: Qt.rgba(16 / 255, 17 / 255, 20 / 255, 0.85) }
            GradientStop { position: 0.66; color: Qt.rgba(16 / 255, 17 / 255, 20 / 255, 0.85) }
            GradientStop { position: 1.00; color: Qt.rgba(16 / 255, 17 / 255, 20 / 255, 0) }
        }
    }

    // ruler: major tick every 64px (full 7px), minor every 8px (3px, bottom), hairline under both
    Canvas {
        id: ruler
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 7
        onWidthChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.fillStyle = Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.35);
            for (let x = 0; x < width; x += 64)
                ctx.fillRect(x, 0, 1, height - 1);
            ctx.fillStyle = Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.18);
            for (let x = 0; x < width; x += 8)
                ctx.fillRect(x, 4, 1, 3);
            ctx.fillStyle = Qt.rgba(1, 1, 1, 0.16);
            ctx.fillRect(0, height - 1, width, 1);
        }
    }
}
