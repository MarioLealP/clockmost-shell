// One picture from HeroArt's folder, filling this item (cover-fit, from the top), swapped through the halftone shader
// whenever the hero swaps (delay = how long after). Picks a picture neither the hero nor this one is showing.
import QtQuick

Item {
    id: root

    property int delay: 0
    property real cell: 9
    property url urlA: ""
    property url urlB: ""
    property bool onB: false
    property bool pending: false
    property real t: 0
    readonly property url showing: onB ? urlB : urlA

    Connections {
        target: HeroArt
        function onFilesChanged() {
            if (String(root.urlA) === "" && HeroArt.files.length) {
                root.urlA = HeroArt.pick(HeroArt.hero);
                root.urlB = root.urlA;
            }
        }
        function onRequestsChanged() { later.restart(); }
    }
    Component.onCompleted: if (HeroArt.files.length) { urlA = HeroArt.pick(HeroArt.hero); urlB = urlA; }
    Timer { id: later; interval: root.delay; onTriggered: root.swap() }

    function swap() {
        if (pending || morph.running)
            return;
        const pool = HeroArt.files.filter(f => String(f) !== String(root.showing) && String(f) !== String(HeroArt.hero));
        const next = pool.length ? pool[Math.floor(Math.random() * pool.length)] : HeroArt.pick(root.showing);
        if (onB)
            urlA = next;
        else
            urlB = next;
        pending = true;
        Qt.callLater(go);
    }
    function go() {
        const img = onB ? imgA : imgB;
        if (!pending || img.status !== Image.Ready)
            return;
        pending = false;
        morph.to = onB ? 0 : 1;
        morph.restart();
    }
    NumberAnimation {
        id: morph
        target: root
        property: "t"
        duration: 3200
        easing.type: Easing.InOutSine
        onFinished: root.onB = !root.onB
    }

    function fitFor(img) {
        const r = width / Math.max(1, height), a = img.implicitWidth / Math.max(1, img.implicitHeight);
        return a > r ? Qt.vector2d(r / a, 1) : Qt.vector2d(1, a / r);
    }
    Image { id: imgA; visible: false; source: root.urlA; sourceSize.width: 1600; asynchronous: true; onStatusChanged: root.go() }
    Image { id: imgB; visible: false; source: root.urlB; sourceSize.width: 1600; asynchronous: true; onStatusChanged: root.go() }

    ShaderEffect {
        anchors.fill: parent
        property variant srcA: imgA
        property variant srcB: imgB
        property real t: root.t
        property real cell: root.cell
        property size size: Qt.size(width, height)
        property vector2d fitA: root.fitFor(imgA)
        property vector2d fitB: root.fitFor(imgB)
        property color bg: GroundTheme.bg
        fragmentShader: Qt.resolvedUrl("shaders/halftone.frag.qsb")
    }
}
