// Media state shared by the bar's now-playing chip and the control center's MEDIA tab: the player (first MPRIS player
// that is playing, else the first one) and the accent = the cover's main colour (the mock: "--acc = the album art's
// colour"). Like the phonograph: the cover's hue and saturation at the mock lavender's lightness, grey covers give a
// quiet tint. CoverSampler feeds pick() with the cover's pixels (ColorQuantizer only reads local files; covers are https).
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) ?? players[0] ?? null
    readonly property bool playing: player?.isPlaying ?? false

    // the mock's default accent: Glassy Sky lavender rgb(207,198,244) = hsl(252, 67.5%, 86.6%)
    property real hue: 252
    property real sat: 0.45
    readonly property color accent: Qt.hsla(hue / 360, 0.675 * Math.max(0.18, Math.min(1, sat / 0.45)), 0.866, 1)

    function clock(seconds) {
        const s = Math.max(0, Math.floor(seconds || 0));
        const mm = String(Math.floor(s % 3600 / 60)).padStart(2, "0") + ":" + String(s % 60).padStart(2, "0");
        return s >= 3600 ? Math.floor(s / 3600) + ":" + mm : mm; // live streams run for hours
    }

    function reset() {
        hue = 252;
        sat = 0.45;
    }

    // RGBA bytes -> the dominant hue: chroma-weighted 10° hue bins, the strongest 30° window wins; near-black,
    // near-white and grey pixels don't vote. Too little colour = a grey cover.
    function pick(data) {
        const w = new Array(36).fill(0), cx = new Array(36).fill(0), cy = new Array(36).fill(0), ss = new Array(36).fill(0);
        let counted = 0, chroma = 0;
        for (let i = 0; i < data.length; i += 4) {
            const r = data[i] / 255, g = data[i + 1] / 255, b = data[i + 2] / 255;
            const mx = Math.max(r, g, b), mn = Math.min(r, g, b), l = (mx + mn) / 2, d = mx - mn;
            if (l < 0.1 || l > 0.94)
                continue;
            counted++;
            const s = d / (1 - Math.abs(2 * l - 1));
            if (s < 0.12)
                continue;
            const h = ((mx === r ? ((g - b) / d) % 6 : mx === g ? (b - r) / d + 2 : (r - g) / d + 4) * 60 + 360) % 360;
            const bin = Math.floor(h / 10) % 36, rad = h * Math.PI / 180;
            w[bin] += d;
            cx[bin] += Math.cos(rad) * d;
            cy[bin] += Math.sin(rad) * d;
            ss[bin] += s * d;
            chroma += d;
        }
        if (!counted || chroma < counted * 0.03) { // grey cover: the lavender, quiet
            hue = 252;
            sat = 0;
            return;
        }
        let best = 0, bestW = -1;
        for (let k = 0; k < 36; k++) {
            const sum = w[(k + 35) % 36] + w[k] + w[(k + 1) % 36];
            if (sum > bestW) {
                bestW = sum;
                best = k;
            }
        }
        let x = 0, y = 0, sw = 0;
        for (const k of [(best + 35) % 36, best, (best + 1) % 36]) {
            x += cx[k];
            y += cy[k];
            sw += ss[k];
        }
        hue = (Math.atan2(y, x) * 180 / Math.PI + 360) % 360;
        sat = sw / bestW;
    }
}
