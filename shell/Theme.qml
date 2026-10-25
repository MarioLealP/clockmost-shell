// Endfield tokens - the values from the mocks' ds-shell.css / ds-topbar-v2.html.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property color ink: "#f1f1f4"
    readonly property color ink2: "#c9ccd3"
    readonly property color dim: "#7d8089"
    readonly property color faint: "#55575e"
    readonly property color yellow: "#ff5f1f" // v2: the one accent is signal orange (name kept: used everywhere)
    readonly property color cyan: "#3FD0E8"
    readonly property color magenta: "#ff1aac"
    readonly property color green: "#7ddb57"
    readonly property color orange: "#ff9e2c"
    readonly property color crimson: "#d91e36"
    readonly property color plateInk: "#111111"

    readonly property string mono: "JetBrains Mono"
    readonly property string body: "Inter"

    // ds-topbar-v2 geometry
    readonly property int band: 88 // v2: room for the 52px plates 18px down from the top edge
    readonly property int plateWidth: 320
    readonly property int plateHeight: 96
    readonly property int triBand: 5
    // the dock plate (ds-dock) and its gap to the bottom edge
    readonly property int dockPlateHeight: 84
    readonly property int dockGapBottom: 14

    // letter-spacing in CSS is em-relative; Qt wants pixels
    function em(sizePx, ems) {
        return sizePx * ems;
    }
}
