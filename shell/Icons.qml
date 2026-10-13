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
    // control center (ds-topbar-v2 ?state=quick, + rail icons in the same stroke style)
    readonly property string home: "M4 11l8-7 8 7 M6 9v11h12V9 M10 20v-6h4v6"
    readonly property string ethernet: "M4 9h16v10H4z M8 9V5h8v4M8 13v2M12 13v2M16 13v2"
    readonly property string dnd: "M6 17V11a6 6 0 0 1 12 0v6l2 2H4z M4 4l16 16"
    readonly property string nightLight: "M20 14A8 8 0 1 1 10 4a6 6 0 0 0 10 10z"
    readonly property string game: "M3 7h18v10H3z M7 12h4M9 10v4M15 11h.01M17 13h.01"
    readonly property string mic: "M9 3h6v11H9z M5 11a7 7 0 0 0 14 0M12 18v3"
    readonly property string media: "M3 12a9 9 0 1 0 18 0a9 9 0 1 0 -18 0 M10 12a2 2 0 1 0 4 0a2 2 0 1 0 -4 0"
    readonly property string calendar: "M4 6h16v14H4z M4 10h16 M8 3v5M16 3v5"
    readonly property string prev: "M18 6v12L8 12z M6 6v12"
    readonly property string next: "M6 6v12l10-6z M18 6v12"
    readonly property string settings: "M9 12a3 3 0 1 0 6 0a3 3 0 1 0 -6 0 M12 3v3M12 18v3M3 12h3M18 12h3M6 6l2 2M16 16l2 2M18 6l-2 2M8 16l-2 2"
    readonly property string lock: "M5 11h14v10H5z M8 11V7a4 4 0 0 1 8 0v4"
    readonly property string power: "M12 3v9 M6.3 7.5a8 8 0 1 0 11.4 0"

    // bluetooth device types (BlueZ icon names)
    readonly property string headphones: "M4 14v-2a8 8 0 0 1 16 0v2 M4 14h4v6H4z M16 14h4v6h-4z"
    readonly property string mouse: "M7 4h10v16H7z M12 4v6"
    readonly property string keyboard: "M3 7h18v10H3z M7 11h.01M11 11h.01M15 11h.01M8 14h8"
    readonly property string phone: "M8 3h8v18H8z M11 18h2"

    function device(blueZIcon) {
        const i = blueZIcon || "";
        if (i.startsWith("audio")) return headphones;
        if (i === "input-mouse" || i === "input-tablet") return mouse;
        if (i === "input-keyboard") return keyboard;
        if (i === "input-gaming") return game;
        if (i === "phone") return phone;
        return bluetooth;
    }

    function byName(name) {
        const map = { home: home, volume: volume, ethernet: ethernet, bluetooth: bluetooth, media: media, calendar: calendar,
            bell: bell, clipboard: clipboard };
        return map[name] ?? home;
    }

    function weather(name) {
        const map = { sun: sun, moon: moon, cloud: cloud, rain: rain, snow: snow, storm: storm, fog: fog };
        return map[name] ?? sun;
    }
}
