// ds-dock-v2 .dl slot: the downloads stack. Tile rgba(30,32,37,.7) with the yellow corner cut + underbar; three
// 6px outlined bars (left/right 12, top 14/21/28, 1px rgba(241,241,244,.5)); count badge 700 9px mono #111 on ink
// (right 4, top 4, padding 1/4); a 2px progress track (left/right 6, bottom 7) while something is downloading -
// browsers don't publish the total, so the 64% fill of the mock sweeps instead.
import QtQuick

Item {
    id: root

    readonly property color c: Theme.yellow

    width: 56
    height: 56 + 5 + 3

    Item {
        id: tile
        width: 56
        height: 56
        clip: true

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(30 / 255, 32 / 255, 37 / 255, area.containsMouse ? 0.85 : 0.7)
        }
        InsetShadow {
            radius: 0
            offsetY: 2
            blur: 10
            color: Qt.rgba(0, 0, 0, 0.55)
        }
        Repeater {
            model: [14, 21, 28]
            Rectangle {
                required property int modelData
                x: 12
                y: modelData
                width: 56 - 24
                height: 6
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.5)
            }
        }
        Rectangle {
            visible: Downloads.recent > 0
            anchors.right: parent.right
            anchors.rightMargin: 4
            y: 4
            width: cnt.implicitWidth + 8
            height: cnt.implicitHeight + 2
            color: Theme.ink
            Text {
                id: cnt
                anchors.centerIn: parent
                text: Downloads.recent
                color: "#111111"
                font.family: Theme.mono
                font.weight: Font.Bold
                font.pixelSize: 9
            }
        }
        Item {
            visible: Downloads.active
            x: 6
            width: 56 - 12
            height: 2
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 7
            clip: true
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(1, 1, 1, 0.15)
            }
            Rectangle {
                id: sweep
                width: parent.width * 0.64
                height: 2
                color: Theme.yellow
                NumberAnimation on x {
                    running: Downloads.active
                    loops: Animation.Infinite
                    from: -sweep.width
                    to: 56 - 12
                    duration: 1400
                    easing.type: Easing.InOutCubic
                }
            }
        }
        Canvas {
            width: 12
            height: 12
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                ctx.fillStyle = root.c;
                ctx.beginPath();
                ctx.moveTo(0, 0);
                ctx.lineTo(12, 0);
                ctx.lineTo(0, 12);
                ctx.closePath();
                ctx.fill();
            }
        }
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 3
            color: root.c
        }
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.10)
        }
    }

    DockTip {
        z: 10
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height - 82 - height
        opacity: area.containsMouse ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 140 } }
        title: "Downloads"
        sub: (Downloads.active ? "DOWNLOADING · " : "") + Downloads.recent + " TODAY"
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Downloads.open()
    }
}
