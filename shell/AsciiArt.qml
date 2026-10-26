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
    property real presence: HaSections.current !== "" ? 0 : 1
    Behavior on presence {
        SequentialAnimation {
            // closing waits for the section to clear and the line to land
            PauseAnimation { duration: HaSections.current !== "" ? 0 : 450 }
            NumberAnimation { duration: HaSections.current !== "" ? 650 : 900 }
        }
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
        function onRequestsChanged() { scramble.restart(); }
    }
    Component.onCompleted: scramble.restart() // forms on start
    SequentialAnimation {
        id: scramble
        NumberAnimation { target: root; property: "t"; from: 0; to: 1; duration: 2600 }
        ScriptAction { script: root.t = 0 }
    }
    // the scramble's tick, only while it runs
    Timer {
        interval: 50
        repeat: true
        running: scramble.running || (root.presence > 0 && root.presence < 1)
        onTriggered: root.time += 0.05
    }
}
