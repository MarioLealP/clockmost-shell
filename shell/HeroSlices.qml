// Four staggered windows onto one continuous picture (the NEONMOON poster), outlined, with hazard bars + brackets.
// The picture comes from HeroArt (a folder, a random pick every 10 min) and swaps through a halftone: it breaks into
// coloured dots, the dots turn into the next picture's, and that one forms back (shaders/halftone.frag, ~3 s).
import QtQuick

Item {
    id: root

    property url urlA: GroundTheme.art
    property url urlB: GroundTheme.art
    property bool onB: false // which picture is showing
    property bool pending: false // a swap waiting for its picture to load
    property bool started: false
    property real t: 0 // the shader's 0 = A .. 1 = B

    // the first picture: a random one from the folder, no show
    Connections {
        target: HeroArt
        function onFilesChanged() {
            if (root.started || !HeroArt.files.length)
                return;
            root.started = true;
            root.urlA = HeroArt.pick("");
            root.urlB = root.urlA;
        }
        function onRequestsChanged() { root.swap(); }
    }
    Component.onCompleted: HeroArt.rebuild()

    function swap() {
        if (pending || morph.running)
            return;
        const next = HeroArt.pick(onB ? urlB : urlA);
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
            return; // its statusChanged calls back
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

    // cover-fit per picture for the shader: centred across, from the top down (like the old full-width image)
    readonly property real rectAspect: width / (height + 40)
    function fitFor(img) {
        const a = img.implicitWidth / Math.max(1, img.implicitHeight); // the loaded picture
        return a > rectAspect ? Qt.vector2d(rectAspect / a, 1) : Qt.vector2d(1, a / rectAspect);
    }
    Image { id: imgA; visible: false; source: root.urlA; sourceSize.width: 1600; asynchronous: true; onStatusChanged: root.go() }
    Image { id: imgB; visible: false; source: root.urlB; sourceSize.width: 1600; asynchronous: true; onStatusChanged: root.go() }
    property int gap: 26
    // [top, bottom] of each window; the picture is drawn once across the full width so it stays continuous
    property var spans: [[0, 900], [110, 1180], [0, 930], [90, 1060]]
    readonly property real paneW: (width - 3 * gap) / 4

    width: 1120
    height: 1180

    component Hazard: Rectangle {
        property color stripe: GroundTheme.ink
        height: 30
        color: "transparent"
        clip: true
        Row {
            x: -30
            spacing: 14
            Repeater {
                model: Math.ceil(parent.parent.width / 28) + 3
                Rectangle { width: 14; height: 60; y: -15; color: stripe; rotation: 45 }
            }
        }
    }

    Repeater {
        model: root.spans
        Item {
            required property var modelData
            required property int index
            x: index * (root.paneW + root.gap)
            y: modelData[0]
            width: root.paneW
            height: modelData[1] - modelData[0]

            Rectangle {
                anchors.fill: parent
                anchors.margins: -6
                color: "transparent"
                border.width: 2
                border.color: GroundTheme.ink
            }
            Item {
                anchors.fill: parent
                clip: true
                ShaderEffect {
                    x: -parent.parent.x
                    y: -parent.parent.y - 40
                    width: root.width
                    height: root.height + 40
                    property variant srcA: imgA
                    property variant srcB: imgB
                    property real t: root.t
                    property real cell: 14
                    property size size: Qt.size(width, height)
                    property vector2d fitA: root.fitFor(imgA)
                    property vector2d fitB: root.fitFor(imgB)
                    property color bg: GroundTheme.bg
                    fragmentShader: Qt.resolvedUrl("shaders/halftone.frag.qsb")
                }
            }
        }
    }

    Hazard { x: -40; y: -70; width: 300 }
    Hazard { x: root.width - 340; y: root.height + 10; width: 380; stripe: GroundTheme.acc }

    Rectangle { // left bracket
        x: -70; y: 120; width: 40; height: 560
        color: "transparent"
        Rectangle { width: 2; height: parent.height; color: GroundTheme.ink }
        Rectangle { width: parent.width; height: 2; color: GroundTheme.ink }
        Rectangle { y: parent.height - 2; width: parent.width; height: 2; color: GroundTheme.ink }
    }
    Rectangle { // top-right bracket
        x: root.width - 280; y: -70; width: 300; height: 260 // right line 20 px outside the last pane, clear of the Felt column
        color: "transparent"
        Rectangle { width: parent.width; height: 2; color: GroundTheme.ink }
        Rectangle { x: parent.width - 2; width: 2; height: parent.height; color: GroundTheme.ink }
    }
}
