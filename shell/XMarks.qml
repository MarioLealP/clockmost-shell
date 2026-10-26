// Soft white X marks scattered around the art; the two big ones blurred for depth (Good Smile Racing fan art).
// Motion (Mario 2026-10-26: "focus looks interesting, and restrike"), one at random every 25-55 s:
// - re-strike: an X takes its two strokes back and draws them on again, like a pen marking it;
// - focus pull: a sharp X goes soft while a blurred one comes into focus, holds, then they trade back.
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes

Item {
    id: root

    // [x, y, size, stroke, blurred] in ground coordinates
    property var marks: [
        [1560, 255, 60, 22, false], [1610, 375, 40, 16, false], [1650, 475, 26, 11, false],
        [2560, 555, 50, 18, false], [2610, 655, 22, 9, false], [1980, 1135, 34, 12, false],
        [2470, 1105, 150, 60, true], [1480, 75, 110, 44, true]
    ]

    function pickOne(blurred) {
        const ids = marks.map((m, i) => i).filter(i => marks[i][4] === blurred);
        return xs.itemAt(ids[Math.floor(Math.random() * ids.length)]);
    }

    Connections {
        target: HeroArt
        function onMarkPokesChanged() {
            root.pickOne(false).restrike();
            focusPull.start(root.pickOne(false), root.pickOne(true));
        }
    }

    Timer {
        id: next
        interval: 25000 + Math.random() * 30000
        running: true
        onTriggered: {
            if (Math.random() < 0.5)
                root.pickOne(Math.random() < 0.8 ? false : true).restrike();
            else
                focusPull.start(root.pickOne(false), root.pickOne(true));
            interval = 25000 + Math.random() * 30000;
            restart();
        }
    }

    // trade focus between one sharp and one blurred X, hold, trade back
    QtObject {
        id: focusPull
        property Item sharp
        property Item soft
        function start(a, b) {
            if (pull.running)
                return;
            sharp = a;
            soft = b;
            pull.restart();
        }
    }
    SequentialAnimation {
        id: pull
        ParallelAnimation {
            NumberAnimation { target: focusPull.sharp; property: "haze"; to: 1; duration: 1600; easing.type: Easing.InOutSine }
            NumberAnimation { target: focusPull.soft; property: "haze"; to: 0; duration: 1600; easing.type: Easing.InOutSine }
        }
        PauseAnimation { duration: 4000 }
        ParallelAnimation {
            NumberAnimation { target: focusPull.sharp; property: "haze"; to: 0; duration: 1600; easing.type: Easing.InOutSine }
            NumberAnimation { target: focusPull.soft; property: "haze"; to: 1; duration: 1600; easing.type: Easing.InOutSine }
        }
    }

    Repeater {
        id: xs
        model: root.marks
        Item {
            id: mark
            required property var modelData
            readonly property real s: modelData[2]
            property real haze: modelData[4] ? 1 : 0 // 0 = sharp .. 1 = blurred
            property real d1: 1 // how much of each stroke is drawn
            property real d2: 1

            function restrike() {
                if (!strike.running)
                    strike.restart();
            }
            SequentialAnimation {
                id: strike
                NumberAnimation { target: mark; property: "d2"; to: 0; duration: 110; easing.type: Easing.InCubic }
                NumberAnimation { target: mark; property: "d1"; to: 0; duration: 110; easing.type: Easing.InCubic }
                PauseAnimation { duration: 140 }
                NumberAnimation { target: mark; property: "d1"; to: 1; duration: 190; easing.type: Easing.OutCubic }
                NumberAnimation { target: mark; property: "d2"; to: 1; duration: 190; easing.type: Easing.OutCubic }
            }

            // padded so the round caps and the blur aren't cut off at the item's edge
            readonly property real pad: modelData[3] + 40
            x: modelData[0] - pad
            y: modelData[1] - pad
            width: s + 2 * pad
            height: s + 2 * pad
            layer.enabled: true
            layer.effect: MultiEffect { blurEnabled: mark.haze > 0.01; blur: mark.haze; blurMax: 32 }
            opacity: 1 - 0.3 * haze

            Shape {
                x: mark.pad
                y: mark.pad
                width: mark.s
                height: mark.s
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: mark.d1 > 0.02 ? GroundTheme.ink : "transparent"
                    strokeWidth: mark.modelData[3]
                    capStyle: ShapePath.RoundCap
                    fillColor: "transparent"
                    PathMove { x: 0; y: 0 }
                    PathLine { x: mark.s * mark.d1; y: mark.s * mark.d1 }
                }
                ShapePath {
                    strokeColor: mark.d2 > 0.02 ? GroundTheme.ink : "transparent"
                    strokeWidth: mark.modelData[3]
                    capStyle: ShapePath.RoundCap
                    fillColor: "transparent"
                    PathMove { x: mark.s; y: 0 }
                    PathLine { x: mark.s - mark.s * mark.d2; y: mark.s * mark.d2 }
                }
            }
        }
    }
}
