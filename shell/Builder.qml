// Builds a finished piece of UI in on screen, from inside (the motion language, Mario 2026-10-26: "frames then
// details"): first the frames - big framed shapes get an orange trace around their border, thin rules / dividers / bar
// tracks draw out from their start - then the details: small fills and icons pop in, labels flicker on like they're
// being typed, big numbers roll through digits. Everything in order down the screen. Put it on top of what it builds
// (it draws the traces and rolling numbers itself); prepare(items) hides, run() plays, finish() snaps to the end.
// Nothing being built is ever touched: every part starts under a cover in the background colour and the covers do
// the moving (changing opacity / scale on the control center's items wiped the window's alpha - the desktop showed
// through the panel).
import QtQuick

Item {
    id: root

    property real speed: 1 // > 1 = quicker (tab switches)
    property real traceMin: 100 // framed shapes wider than this (and > 40 tall) get the orange trace
    property real originX: -1 // >= 0: parts also build outward from this x (the drawer's deck, from its centre)
    property color cover: GroundTheme.bg // the labels' covers
    property real clock: 0
    property real total: 600
    property var atoms: [] // {item, kind: trace|line|pop|type|roll, start, dur, i, ov (overlay), cv (cover)}
    property var overlays: []
    readonly property bool running: play.running

    function layoutAll(item) {
        for (const c of item.children)
            layoutAll(c);
        if (typeof item.forceLayout === "function")
            item.forceLayout();
    }

    function clear() {
        for (const o of overlays)
            o.destroy();
        overlays = [];
    }

    function finish() {
        play.stop();
        clear();
        atoms = [];
        total = 0;
    }

    // hide everything to build in `items` (their own frames stay where they are, their insides go); reversed = start
    // from built, for taking it apart by running the clock back to 0
    function prepare(items, reversed) {
        finish();
        const list = [];
        const at = c => c.mapToItem(root, 0, 0);
        const k = 1 / speed;
        const walk = item => {
            for (const c of item.children) {
                if (!c.visible || c.width <= 0 || c.height <= 0 || c === root || c.objectName === "nobuild")
                    continue;
                const p = at(c);
                const isText = c.font !== undefined && c.text !== undefined;
                const isRect = c.border !== undefined && c.radius !== undefined;
                const isImage = c.fillMode !== undefined && c.source !== undefined && c.sourceSize !== undefined;
                const leaf = c.children.length === 0 || c.children.every(x => x.width <= 0 || !x.visible);
                // something that draws (input-only items - MouseAreas, plain Items - get no cover)
                const drawn = c.color !== undefined || isImage || c.fragmentShader !== undefined;
                // outward from originX: the distance of the part's centre from it
                const out = originX >= 0 ? Math.abs(p.x + c.width / 2 - originX) * 0.45 : 0;
                if (c.objectName === "buildline") {
                    // a composite rule (the hazard strips): drawn out as one line, its insides untouched
                    list.push({ item: c, kind: "line", start: (p.y * 0.25 + out) * k, dur: 420 * k });
                } else if (isText) {
                    const big = c.font.pixelSize >= 40 && /\d/.test(c.text);
                    list.push({ item: c, kind: big ? "roll" : "type", start: (260 + p.y * 0.35 + (originX >= 0 ? out : p.x * 0.05)) * k, dur: (big ? 520 : 200) * k });
                } else if (isRect && c.border.width > 0 && c.width > traceMin && c.height > 40) {
                    list.push({ item: c, kind: "trace", start: (p.y * 0.2 + out) * k, dur: 420 * k });
                    walk(c);
                } else if (isRect && leaf && (c.height <= 2 || c.width <= 2)) {
                    list.push({ item: c, kind: "line", start: p.y * 0.25 * k, dur: 240 * k });
                } else if ((leaf && drawn) || isImage) {
                    list.push({ item: c, kind: "pop", start: (200 + p.y * 0.3 + (originX >= 0 ? out : p.x * 0.05)) * k, dur: 220 * k });
                    if (isImage)
                        walk(c);
                } else {
                    walk(c);
                }
            }
        };
        for (const it of items) {
            layoutAll(it);
            walk(it);
        }
        list.forEach((a, i) => {
            a.i = i;
            if (a.kind !== "trace")
                a.cv = coverFor(a.item);
        });
        atoms = list;
        total = list.reduce((m, a) => Math.max(m, a.start + a.dur), 300) + 40;
        clock = reversed ? total : 0;
        if (reversed)
            step(); // the covers are up already: drop them before a frame shows them
    }
    // a background-coloured block over a label, 1 px proud on every side
    function coverFor(item) {
        const pos = item.mapToItem(root, 0, 0);
        const c = Qt.createQmlObject("import QtQuick; Rectangle {}", root);
        c.x = pos.x - 1;
        c.y = pos.y - 1;
        c.width = item.width + 2;
        c.height = item.height + 2;
        c.color = root.cover;
        overlays = overlays.concat([c]);
        return c;
    }

    function run() {
        play.restart();
    }

    NumberAnimation {
        id: play
        target: root
        property: "clock"
        from: 0
        to: root.total
        duration: root.total
        onFinished: root.finish()
    }

    // every part's state is a pure function of its progress p (0 = hidden, 1 = built), so the clock runs either way;
    // covers and overlays are kept (hidden) until finish()
    function trace(a, p) {
        if (!a.ov) {
            const pos = a.item.mapToItem(root, 0, 0);
            a.ov = Qt.createQmlObject("import QtQuick; Item { Rectangle { height: 2 } Rectangle { width: 2 } Rectangle { height: 2 } Rectangle { width: 2 } }", root);
            a.ov.x = pos.x;
            a.ov.y = pos.y;
            overlays = overlays.concat([a.ov]);
        }
        a.ov.visible = p > 0 && p < 1;
        const w = a.item.width, h = a.item.height, d = p * 2 * (w + h);
        const [top, right, bottom, left] = a.ov.children;
        top.width = Math.min(d, w);
        right.x = w - 2;
        right.height = Math.max(0, Math.min(d - w, h));
        bottom.y = h - 2;
        bottom.width = Math.max(0, Math.min(d - w - h, w));
        bottom.x = w - bottom.width;
        left.height = Math.max(0, Math.min(d - 2 * w - h, h));
        left.y = h - left.height;
        // the trace cools from orange into the frame's own hairline (a colour, never opacity - cm-1jun)
        const k = p < 0.85 ? 0 : (p - 0.85) / 0.15;
        for (const r of a.ov.children)
            r.color = Qt.tint(GroundTheme.acc, Qt.rgba(GroundTheme.lineSolid.r, GroundTheme.lineSolid.g, GroundTheme.lineSolid.b, k));
    }
    function roll(a, p) {
        if (!a.ov) {
            const pos = a.item.mapToItem(root, 0, 0);
            a.ov = Qt.createQmlObject("import QtQuick; Text {}", root);
            a.ov.x = pos.x;
            a.ov.y = pos.y;
            a.ov.font = a.item.font;
            a.ov.color = a.item.color;
            a.ov.lineHeightMode = a.item.lineHeightMode;
            a.ov.lineHeight = a.item.lineHeight;
            a.ov.z = 1; // above the label's cover
            overlays = overlays.concat([a.ov]);
        }
        a.ov.visible = p > 0 && p < 1;
        a.cv.visible = p < 1;
        if (a.ov.visible)
            a.ov.text = a.item.text.replace(/\d/g, () => String(Math.floor(Math.random() * 10)));
    }

    function step() {
        for (const a of atoms) {
            if (!a.item) { // its tab was swapped out mid-build
                if (a.cv)
                    a.cv.visible = false;
                if (a.ov)
                    a.ov.visible = false;
                continue;
            }
            const p = Math.max(0, Math.min(1, (clock - a.start) / a.dur));
            const e = 1 - Math.pow(1 - p, 3);
            if (a.kind === "trace") {
                if (p > 0 || a.ov)
                    trace(a, p);
            } else if (a.kind === "roll") {
                roll(a, p);
            } else if (a.kind === "line") {
                // the cover slides off from the start edge: the line draws out
                const r = a.item.mapToItem(root, 0, 0);
                a.cv.visible = p < 1;
                if (a.item.width >= a.item.height) {
                    a.cv.x = r.x - 1 + a.item.width * e;
                    a.cv.width = a.item.width * (1 - e) + 2;
                } else {
                    a.cv.y = r.y - 1 + a.item.height * e;
                    a.cv.height = a.item.height * (1 - e) + 2;
                }
            } else if (a.kind === "type") {
                // the cover flickers off: hard blinks while it runs, then gone
                a.cv.visible = p <= 0 || (p < 1 && (Math.floor(clock / 45) + a.i) % 3 !== 1 && p < 0.35 + 0.65 * ((a.i * 7) % 10) / 10);
            } else {
                // pop: the cover shrinks into the middle of the part
                a.cv.visible = p < 1;
                a.cv.scale = 1 - e;
            }
        }
    }
    onClockChanged: step()
}
