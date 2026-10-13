// ds-dock-v2 .drawer: 56px olive slab - linear-gradient(180deg, rgba(255,250,0,.30), rgba(255,250,0,.55)),
// 1px rgba(255,250,0,.45) border, #fffbb0 2x2 grid glyph (22px, stroke 2.4); ::after = 6px dot grid
// rgba(255,250,0,.35) masked by linear-gradient(135deg, transparent 45%, #000); "WIN" 700 7px mono .14em #d8d36a.
import QtQuick

Item {
    id: root

    width: 56
    height: 56

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(1, 250 / 255, 0, area.containsMouse ? 0.38 : 0.30) }
            GradientStop { position: 1; color: Qt.rgba(1, 250 / 255, 0, area.containsMouse ? 0.65 : 0.55) }
        }
        border.width: 1
        border.color: Qt.rgba(1, 250 / 255, 0, 0.45)
    }

    // the dot grid with the 135deg mask folded in: on a square the gradient runs corner to corner, so a dot at
    // (x, y) sits at t = (x + y) / (w + h); alpha 0 until t = .45, then linear to 1
    Canvas {
        anchors.fill: parent
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            for (let y = 3; y < height; y += 6) {
                for (let x = 3; x < width; x += 6) {
                    const t = (x + y) / (width + height);
                    const a = Math.max(0, Math.min(1, (t - 0.45) / 0.55));
                    if (a <= 0)
                        continue;
                    ctx.fillStyle = Qt.rgba(1, 250 / 255, 0, 0.35 * a);
                    ctx.beginPath();
                    ctx.arc(x, y, 1.15, 0, 2 * Math.PI);
                    ctx.fill();
                }
            }
        }
    }

    Canvas {
        anchors.centerIn: parent
        width: 22
        height: 22
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.strokeStyle = "#fffbb0";
            ctx.scale(22 / 24, 22 / 24);
            ctx.lineWidth = 2.4;
            for (const [x, y] of [[4, 4], [14, 4], [4, 14], [14, 14]])
                ctx.strokeRect(x, y, 6, 6);
        }
    }

    Text {
        x: 5
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        text: "WIN"
        color: "#d8d36a"
        font.family: Theme.mono
        font.weight: Font.Bold
        font.pixelSize: 7
        font.letterSpacing: Theme.em(7, 0.14)
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Drawer.toggle()
    }
}
