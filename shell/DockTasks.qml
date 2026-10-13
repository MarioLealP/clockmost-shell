// The task-manager button, where ds-dock-v2's downloads stack was (Mario: keep the stack icon). Same tile: rgba(30,32,37,.7)
// with the yellow corner cut + underbar; three 6px outlined bars (left/right 12, top 14/21/28, 1px
// rgba(241,241,244,.5)). No count / progress. Click = Plasma's System Monitor, or top in kitty until one is
// installed (our own task manager replaces this later).
import QtQuick
import Quickshell

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
        title: "Task manager"
        sub: "PROCESSES · " + KWin.windows.length + " WIN"
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const e = DesktopEntries.byId("org.kde.plasma-systemmonitor");
            if (e)
                e.execute();
            else
                Quickshell.execDetached(["kitty", "--title", "Task manager", "top"]);
        }
    }
}
