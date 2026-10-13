// The mocks' icon paths (24-unit viewBox), circles rewritten as arcs for PathSvg.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    readonly property string sun: "M8 12a4 4 0 1 0 8 0a4 4 0 1 0 -8 0 M12 2v3M12 19v3M2 12h3M19 12h3M5 5l2 2M17 17l2 2M19 5l-2 2M7 17l-2 2"
    readonly property string moon: "M20 14a8 8 0 1 1 -10 -10a6 6 0 0 0 10 10z"
    readonly property string cloud: "M7 18h10a4 4 0 0 0 0 -8a6 6 0 0 0 -11.5 1.5A3.5 3.5 0 0 0 7 18z"
    readonly property string rain: "M7 15h10a4 4 0 0 0 0 -8a6 6 0 0 0 -11.5 1.5A3.5 3.5 0 0 0 7 15z M8 18l-1 3M12 18l-1 3M16 18l-1 3"
    readonly property string snow: "M7 15h10a4 4 0 0 0 0 -8a6 6 0 0 0 -11.5 1.5A3.5 3.5 0 0 0 7 15z M8 19h0.01M12 20h0.01M16 19h0.01"
    readonly property string storm: "M7 15h10a4 4 0 0 0 0 -8a6 6 0 0 0 -11.5 1.5A3.5 3.5 0 0 0 7 15z M13 15l-3 4h4l-3 4"
    readonly property string fog: "M4 9h16M6 13h12M4 17h16"
    readonly property string clipboard: "M6 5h12v16H6z M9 3h6v4H9z"
    readonly property string volume: "M4 9h4l5-4v14l-5-4H4z M16 9a4 4 0 0 1 0 6"
    readonly property string volumeMuted: "M4 9h4l5-4v14l-5-4H4z M16 9l5 6M21 9l-5 6"
    readonly property string bluetooth: "M7 7l10 10-5 4V3l5 4L7 17"
    readonly property string vpn: "M12 3l7 3v6c0 4-3 7-7 9-4-2-7-5-7-9V6z"
    readonly property string bell: "M6 17V11a6 6 0 0 1 12 0v6l2 2H4z M10 21h4"

    function weather(name) {
        const map = { sun: sun, moon: moon, cloud: cloud, rain: rain, snow: snow, storm: storm, fog: fog };
        return map[name] ?? sun;
    }
}
