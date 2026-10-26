// The hero's current picture as ASCII art (shaders/ascii.frag), right of the orange line. It follows HeroArt.hero:
// on a swap the characters scramble and settle on the new picture. Static between swaps; fades while an HA section is
// open (it would sit behind it).
import QtQuick

ShaderEffect {
    id: root

    property url urlA: ""
    property url urlB: ""
    property bool onB: false // which image holds the picture shown
    property bool pending: false
    property real t: 0
    property real time: 0

    property variant from: onB ? imgB : imgA
    property variant to: onB ? imgA : imgB
    property size size: Qt.size(width, height)
    property vector2d fitFrom: fitFor(onB ? imgB : imgA)
    property vector2d fitTo: fitFor(onB ? imgA : imgB)
    property color ink: GroundTheme.ink
    property color hot: GroundTheme.acc

    width: 912
    height: 312
    opacity: HaSections.current !== "" ? 0 : 1
    Behavior on opacity { NumberAnimation { duration: 260 } }
    fragmentShader: Qt.resolvedUrl("shaders/ascii.frag.qsb")

    function fitFor(img) {
        const r = width / Math.max(1, height), a = img.implicitWidth / Math.max(1, img.implicitHeight);
        return a > r ? Qt.vector2d(r / a, 1) : Qt.vector2d(1, a / r);
    }

    Connections {
        target: HeroArt
        function onHeroChanged() { root.follow(); }
    }
    Component.onCompleted: follow()
    function follow() {
        const url = HeroArt.hero;
        if (String(url) === "")
            return;
        if (String(urlA) === "") { // the first picture: no show
            urlA = url;
            urlB = url;
            return;
        }
        if (String(url) === String(onB ? urlB : urlA))
            return;
        if (onB)
            urlA = url;
        else
            urlB = url;
        pending = true;
        Qt.callLater(go);
    }
    function go() {
        const img = onB ? imgA : imgB;
        if (!pending || img.status !== Image.Ready)
            return;
        pending = false;
        swap.restart();
    }
    SequentialAnimation {
        id: swap
        NumberAnimation { target: root; property: "t"; from: 0; to: 1; duration: 2600 }
        ScriptAction { script: { root.onB = !root.onB; root.t = 0; } }
    }
    // the scramble's tick, only while swapping
    Timer {
        interval: 50
        repeat: true
        running: swap.running
        onTriggered: root.time += 0.05
    }

    Image { id: imgA; visible: false; source: root.urlA; sourceSize.width: 800; asynchronous: true; onStatusChanged: root.go() }
    Image { id: imgB; visible: false; source: root.urlB; sourceSize.width: 800; asynchronous: true; onStatusChanged: root.go() }
}
