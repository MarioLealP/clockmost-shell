// Endfield tokens - the values from the mocks' ds-shell.css / ds-topbar-v2.html.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    // v2 (2026-10-25): the ground's bone ink scale - everything built on Theme follows the new desktop
    readonly property color ink: "#e8e6df"
    readonly property color ink2: "#c9c7c0"
    readonly property color dim: "#8a8881"
    readonly property color faint: "#55554f"
    readonly property color yellow: "#ff5f1f" // v2: the one accent is signal orange (name kept: used everywhere)
    // v2: one loud colour - the old cyan / magenta / green tags become bone; crimson stays for real errors
    readonly property color cyan: "#e8e6df"
    readonly property color magenta: "#e8e6df"
    readonly property color green: "#e8e6df"
    readonly property color orange: "#ff5f1f"
    readonly property color crimson: "#d91e36"
    readonly property color plateInk: "#111111"

    readonly property string mono: "JetBrains Mono"
    readonly property string body: GroundTheme.display // v2: Archivo

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
