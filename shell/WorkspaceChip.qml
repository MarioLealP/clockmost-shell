// .wsp: a steel plate per desktop; the active one is an olive slab with a dot grid fading in from the left.
// Under the number, one 8x3 mark per window, in that app's colour. Click = switch to it.
import QtQuick

Item {
    id: root

    required property var desktop // {id, name, number}
    readonly property bool active: KWin.current === desktop.id
    readonly property var windows: KWin.windowsOn(desktop.id)

    width: 58
    height: 34

    Rectangle {
        anchors.fill: parent
        color: root.active ? Qt.rgba(1, 95 / 255, 31 / 255, 0.34) : Qt.rgba(51 / 255, 54 / 255, 60 / 255, 0.55)
        border.width: 1
        border.color: root.active ? Qt.rgba(1, 95 / 255, 31 / 255, 0.45) : Qt.rgba(1, 1, 1, area.containsMouse ? 0.22 : 0.08)
        Behavior on color { ColorAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: 160 } }
    }

    // dot grid, masked: transparent for the left 40%, full at the right edge
    Canvas {
        anchors.fill: parent
        opacity: root.active ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160 } }
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            for (let y = 3; y < height; y += 6) {
                for (let x = 3; x < width; x += 6) {
                    const t = Math.max(0, (x / width - 0.4) / 0.6);
                    ctx.fillStyle = Qt.rgba(1, 95 / 255, 31 / 255, 0.35 * t);
                    ctx.beginPath();
                    ctx.arc(x, y, 1, 0, 2 * Math.PI);
                    ctx.fill();
                }
            }
        }
    }

    Text {
        x: 7
        y: 5
        text: String(root.desktop.number).padStart(2, "0")
        color: root.active ? "#ffc9b3" : Theme.dim
        font.family: Theme.mono
        font.weight: Font.Bold
        font.pixelSize: 13
        font.letterSpacing: Theme.em(13, 0.1)
        Behavior on color { ColorAnimation { duration: 160 } }
    }

    Row {
        x: 7
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 5
        spacing: 3
        Repeater {
            model: root.windows.slice(0, 5)
            Rectangle {
                required property var modelData
                width: 8
                height: 3
                color: AppColors.of(modelData.app)
                opacity: modelData.minimized ? 0.4 : 1
            }
        }
    }

    AttentionPin {
        visible: root.windows.some(w => w.attention)
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: KWin.switchTo(root.desktop.id)
    }
}
