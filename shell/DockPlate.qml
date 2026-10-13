// ds-dock-v2 plate (.dock::before / ::after / .bk): the bar's band material, flipped -
//   background (top layer first): linear-gradient(90deg, rgba(16,17,20,0), .85 at 30%, .85 at 70%, 0),
//     repeating-linear-gradient(135deg, rgba(255,255,255,.055) 0 1px, transparent 1px 7px),
//     linear-gradient(180deg, rgba(30,31,36,.92), rgba(16,17,20,.9)); border 1px rgba(255,255,255,.12)
//   tick ruler along the TOP edge: 1px rgba(241,241,244,.35) every 64px (7px tall), 1px .18 every 8px (3px tall)
//   brackets: 12px L-corners, 2px rgba(241,241,244,.5), top-left and bottom-right, 2px outside the plate
// Square corners.
import QtQuick

Item {
    id: root

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(30 / 255, 31 / 255, 36 / 255, 0.92) }
            GradientStop { position: 1; color: Qt.rgba(16 / 255, 17 / 255, 20 / 255, 0.90) }
        }
    }
    Hatch {
        anchors.fill: parent
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.00; color: Qt.rgba(16 / 255, 17 / 255, 20 / 255, 0) }
            GradientStop { position: 0.30; color: Qt.rgba(16 / 255, 17 / 255, 20 / 255, 0.85) }
            GradientStop { position: 0.70; color: Qt.rgba(16 / 255, 17 / 255, 20 / 255, 0.85) }
            GradientStop { position: 1.00; color: Qt.rgba(16 / 255, 17 / 255, 20 / 255, 0) }
        }
    }
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.12)
    }

    Canvas {
        width: parent.width
        height: 7
        onWidthChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.fillStyle = Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.35);
            for (let x = 0; x < width; x += 64)
                ctx.fillRect(x, 0, 1, 7);
            ctx.fillStyle = Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.18);
            for (let x = 0; x < width; x += 8)
                ctx.fillRect(x, 0, 1, 3);
        }
    }

    // brackets
    Item {
        x: -2
        y: -2
        width: 12
        height: 12
        Rectangle { width: 2; height: 12; color: Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.5) }
        Rectangle { width: 12; height: 2; color: Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.5) }
    }
    Item {
        x: root.width + 2 - 12
        y: root.height + 2 - 12
        width: 12
        height: 12
        Rectangle { x: 10; width: 2; height: 12; color: Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.5) }
        Rectangle { y: 10; width: 12; height: 2; color: Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.5) }
    }
}
