// The halftone field (shaders/field.frag) in the stretch right of the orange line: a slow wave, a pulse on every art
// swap, fades away while an HA section is open (it would sit behind it). Updated 15 times a second - it's slow.
import QtQuick

ShaderEffect {
    id: root

    property real time: 0
    property real pulse: -1
    property real cell: 12
    property size size: Qt.size(width, height)
    property color hot: GroundTheme.acc
    property color cold: GroundTheme.ink

    width: 912
    height: 312
    opacity: HaSections.current !== "" ? 0 : 1
    Behavior on opacity { NumberAnimation { duration: 260 } }
    fragmentShader: Qt.resolvedUrl("shaders/field.frag.qsb")

    Timer {
        interval: 66
        repeat: true
        running: root.visible && root.opacity > 0
        onTriggered: root.time += 0.066
    }
    Connections {
        target: HeroArt
        function onRequestsChanged() { sweep.restart(); }
    }
    SequentialAnimation {
        id: sweep
        NumberAnimation { target: root; property: "pulse"; from: 0; to: 1; duration: 2400; easing.type: Easing.InOutSine }
        ScriptAction { script: root.pulse = -1 }
    }
}
