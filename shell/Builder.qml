// Builds a finished piece of UI in on screen, from inside (the motion language, Mario 2026-10-26: "frames then
// details"): first the frames - big framed shapes get an orange trace around their border, thin rules / dividers / bar
// tracks draw out from their start - then the details: small fills and icons pop in, labels flicker on like they're
// being typed, big numbers roll through digits. Everything in order down the screen. Put it on top of what it builds
// (it draws the traces and rolling numbers itself); prepare(items) hides, run() plays, finish() snaps to the end.
import QtQuick

Item {
    id: root

    property real speed: 1 // > 1 = quicker (tab switches)
    property real clock: 0
    property real total: 600
    property var atoms: [] // {item, kind: trace|line|pop|type|roll, start, dur, i, ov, done}
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
        for (const a of atoms) {
            a.item.opacity = 1;
            a.item.scale = 1;
            a.ov = null;
            a.done = true;
        }
        atoms = [];
    }

    // hide everything to build in `items` (their own frames stay where they are, their insides go)
    function prepare(items) {
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
                if (isText) {
                    const big = c.font.pixelSize >= 40 && /\d/.test(c.text);
                    list.push({ item: c, kind: big ? "roll" : "type", start: (260 + p.y * 0.35 + p.x * 0.05) * k, dur: (big ? 520 : 200) * k });
                } else if (isRect && c.border.width > 0 && c.width > 100 && c.height > 40) {
                    list.push({ item: c, kind: "trace", start: p.y * 0.2 * k, dur: 420 * k });
                    walk(c);
                } else if (isRect && leaf && (c.height <= 2 || c.width <= 2)) {
                    list.push({ item: c, kind: "line", start: p.y * 0.25 * k, dur: 240 * k });
                } else if (leaf || isImage) {
                    list.push({ item: c, kind: "pop", start: (200 + p.y * 0.3 + p.x * 0.05) * k, dur: 220 * k });
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
            if (a.kind === "line") {
                a.item.transformOrigin = a.item.height <= 2 ? Item.Left : Item.Top;
                a.item.scale = 0; // scaling up from its start edge reads as the line drawing out
            }
            if (a.kind !== "trace")
                a.item.opacity = 0;
        });
        atoms = list;
        total = list.reduce((m, a) => Math.max(m, a.start + a.dur), 300) + 40;
        clock = 0;
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

    function trace(a, p) {
        if (!a.ov) {
            const pos = a.item.mapToItem(root, 0, 0);
            a.ov = Qt.createQmlObject("import QtQuick; Item { Rectangle { height: 2 } Rectangle { width: 2 } Rectangle { height: 2 } Rectangle { width: 2 } }", root);
            a.ov.x = pos.x;
            a.ov.y = pos.y;
            for (const r of a.ov.children)
                r.color = GroundTheme.acc;
            overlays = overlays.concat([a.ov]);
        }
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
        a.ov.opacity = p < 0.85 ? 1 : (1 - p) / 0.15;
        if (p >= 1)
            drop(a);
    }
    function roll(a, p) {
        if (p >= 1) {
            drop(a);
            a.item.opacity = 1;
            return;
        }
        if (!a.ov) {
            const pos = a.item.mapToItem(root, 0, 0);
            a.ov = Qt.createQmlObject("import QtQuick; Text {}", root);
            a.ov.x = pos.x;
            a.ov.y = pos.y;
            a.ov.font = a.item.font;
            a.ov.color = a.item.color;
            a.ov.lineHeightMode = a.item.lineHeightMode;
            a.ov.lineHeight = a.item.lineHeight;
            overlays = overlays.concat([a.ov]);
        }
        a.ov.text = a.item.text.replace(/\d/g, () => String(Math.floor(Math.random() * 10)));
        a.ov.opacity = Math.min(1, p * 4);
    }
    function drop(a) {
        if (a.ov) {
            a.ov.destroy();
            overlays = overlays.filter(o => o !== a.ov);
            a.ov = null;
        }
        a.done = true;
    }

    onClockChanged: {
        for (const a of atoms) {
            if (a.done)
                continue;
            const p = Math.max(0, Math.min(1, (clock - a.start) / a.dur));
            if (p <= 0)
                continue;
            const e = 1 - Math.pow(1 - p, 3);
            if (a.kind === "trace") {
                trace(a, p);
            } else if (a.kind === "roll") {
                roll(a, p);
            } else if (a.kind === "line") {
                a.item.opacity = 1;
                a.item.scale = e;
                a.done = p >= 1;
            } else if (a.kind === "type") {
                a.item.opacity = p >= 1 ? 1 : ((Math.floor(clock / 45) + a.i) % 3 === 0 ? 0.15 : 0.5 + p / 2);
                a.done = p >= 1;
            } else {
                a.item.opacity = e;
                a.item.scale = 0.6 + 0.4 * e;
                a.done = p >= 1;
            }
        }
    }
}
