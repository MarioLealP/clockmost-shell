// The one accent line: a 6px bar, rotated 28deg off vertical, top-left anchored (runs down to the left).
// Moving it (targetX) is the motion (Mario 2026-10-26): it splits at the middle, the halves shoot off-screen along the
// line (top half up, bottom half down), the line jumps, and the reverse plays where it lands - fast out, fast in then
// still. away() fires the moment both halves are off-screen (the ground swaps what the line was in the way of).
// hold: the landing waits, off-screen, until it drops (the ASCII silhouette is still dissolving where it lands).
import QtQuick

Item {
    id: root

    property real targetX: 0
    property real split: 0 // 0 = whole .. 1 = both halves off-screen
    property bool ready: false
    property bool hold: false
    property bool waiting: false
    onHoldChanged: if (!hold && waiting) {
        waiting = false;
        land.restart();
    }
    signal away

    width: 6
    height: 2200
    rotation: 28
    transformOrigin: Item.TopLeft

    Component.onCompleted: {
        x = targetX;
        ready = true;
    }
    onTargetXChanged: if (ready) move.restart()
    // the startup build-in: off-screen at once, then the usual landing
    function enter() {
        move.stop();
        split = 1;
        land.restart();
    }

    Rectangle {
        width: parent.width
        height: parent.height / 2
        y: -root.split * 1300
        color: GroundTheme.acc
    }
    Rectangle {
        width: parent.width
        height: parent.height / 2
        y: parent.height / 2 + root.split * 1300
        color: GroundTheme.acc
    }

    SequentialAnimation {
        id: move
        ScriptAction { script: { land.stop(); root.waiting = false; } }
        NumberAnimation { target: root; property: "split"; to: 1; duration: 260; easing.type: Easing.InCubic }
        ScriptAction {
            script: {
                root.x = root.targetX;
                root.away();
                if (root.hold)
                    root.waiting = true;
                else
                    land.restart();
            }
        }
    }
    NumberAnimation { id: land; target: root; property: "split"; to: 0; duration: 480; easing.type: Easing.OutQuart }
}
