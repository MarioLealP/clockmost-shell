// v2 desktop ("ground") tokens - graphite, bone ink, one orange accent (desktop-environment-v2, 2026-10-25).
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property color bg: "#1a1a18"
    readonly property color ink: "#e8e6df"
    readonly property color ink2: "#8a8881"
    readonly property color line: Qt.rgba(0.91, 0.9, 0.87, 0.15)
    readonly property color faint: Qt.rgba(0.91, 0.9, 0.87, 0.09)
    readonly property color acc: "#ff5f1f"
    // solid versions over bg, for the control center: on Qt 6.12 a translucent fill there can draw as a hole to the
    // desktop once its build motion has run (cm-1jun), so the control center only uses solid colours
    readonly property color lineSolid: Qt.tint(bg, line)
    readonly property color faintSolid: Qt.tint(bg, faint)
    function over(c) { return Qt.tint(bg, c); }
    readonly property color accInk: "#111110"
    // bumped to replay every ground's startup build-in (ipc: ground intro)
    property int introPokes: 0

    readonly property string mono: "JetBrains Mono"
    readonly property string display: archivo.status === FontLoader.Ready ? archivo.name : "Inter"

    // Archivo (OFL, bundled): a variable font - weight and width (wdth 62-125) per Text via font.variableAxes
    readonly property FontLoader archivo: FontLoader {
        source: Qt.resolvedUrl("assets/fonts/Archivo-Variable.ttf")
    }

    // the character art behind the slices: any picture, kept outside the repo
    readonly property string art: "file://" + Quickshell.env("HOME") + "/.config/clockmost/ground-art.jpg"
}
