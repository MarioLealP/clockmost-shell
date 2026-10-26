// A silhouette as ASCII art (shaders/ascii.frag) right of the orange line - the picture is private:
// ~/.config/clockmost/ascii-art.png (Mario 2026-10-26: the FFXIV meteor; not in the repo). Static; scrambles and
// re-forms on every hero art swap. Dissolves while an HA section is open (it would sit behind it) and materializes
// again when it closes. No file: nothing.
import QtQuick
import Quickshell

ShaderEffect {
    id: root

    property real t: 0
    property real time: 0
    property real presence: 1
    property real fromEmpty: 1
    property real phase: 0
    // the shading drifts (Mario 2026-10-26: "make it slowly cycle", then "slower"), one cycle ~20 s; 5 updates a second
    Timer {
        interval: 200
        repeat: true
        running: root.visible && root.presence > 0
        onTriggered: root.phase = (root.phase + 0.063) % (2 * Math.PI)
    }
    // an HA section opens: dissolve; it closes: wait for it to clear and the line to land, then the start-up
    // scramble from nothing
    Connections {
        target: HaSections
        function onCurrentChanged() {
            if (HaSections.current !== "") {
                form.stop();
                dissolve.restart();
            } else if (root.presence < 1 || dissolve.running) {
                dissolve.stop();
                form.restart();
            }
        }
    }
    NumberAnimation { id: dissolve; target: root; property: "presence"; to: 0; duration: 450 }
    SequentialAnimation {
        id: form
        PauseAnimation { duration: 450 }
        ScriptAction { script: { root.fromEmpty = 1; root.presence = 1; scramble.restart(); } }
    }
    property variant src: img
    property size size: Qt.size(width, height)
    property color ink: GroundTheme.ink

    width: 576
    height: 576
    visible: img.status === Image.Ready
    fragmentShader: Qt.resolvedUrl("shaders/ascii.frag.qsb")

    Image {
        id: img
        visible: false
        source: "file://" + Quickshell.env("HOME") + "/.config/clockmost/ascii-art.png"
        sourceSize.width: 600
        asynchronous: true
    }

    Connections {
        target: HeroArt
        function onRequestsChanged() {
            if (root.presence >= 1 && !scramble.running)
                scramble.restart();
        }
    }
    Component.onCompleted: scramble.restart() // forms on start, from nothing
    SequentialAnimation {
        id: scramble
        NumberAnimation { target: root; property: "t"; from: 0; to: 1; duration: 2600 }
        ScriptAction { script: { root.t = 0; root.fromEmpty = 0; } }
    }
    // the scramble's tick, only while it runs
    Timer {
        interval: 50
        repeat: true
        running: scramble.running || dissolve.running
        onTriggered: root.time += 0.05
    }
}
