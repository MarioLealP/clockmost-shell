// The HA section's place on the ground and its motion (Mario 2026-10-26). Opening waits for the line (lineAway() is
// GroundLine.away): a solid orange slab - a transitional piece, never part of the final UI - wipes across the title
// row and pulls away the other way, uncovering it ("do the sweep for the title, then drop the content"). Then every
// section builds the same way, from inside ("the outlines show up, and then the details"): per block, in order down
// the screen, the block lands (drops 24 px), framed shapes get an orange trace around their border, then the small
// squares / dots / grid cells pop or flicker on, pictures fade in as their frame's trace ends, then the labels
// flicker on like they're being typed and big numbers roll through digits before settling. Close: the content fades while the slab wipes back over the title, the section
// unloads under it, the slab leaves. Switching: the same cover, swap under the slab, reveal.
import QtQuick

Item {
    id: stage

    property var sections: ({}) // name -> Component
    readonly property string current: HaSections.current
    property string shown: ""
    property real slabL: 0 // the slab's edges, 0..1 of the title row
    property real slabR: 0
    property real clock: 0 // the build's time, ms
    property real total: 600
    property real boxW: 560
    property real boxH: 64 // the title row
    property var blocks: [] // {item, tr, y, start}
    property var atoms: [] // {item, kind: trace|pop|flicker|type|roll, start, dur, i, ov, done}
    property var overlays: [] // stand-ins alive right now (traces, rolling numbers)

    // something else has to clear first (the ASCII silhouette dissolving): opening waits until hold drops
    property bool hold: false
    property bool armed: false
    onHoldChanged: if (!hold && armed) lineAway()

    function lineAway() {
        armed = false;
        if (current === "" || shown !== "")
            return;
        if (hold)
            armed = true;
        else
            shown = current;
    }

    onCurrentChanged: {
        if (shown === "")
            return; // opening: waits for the line
        if (current === "")
            closing.restart();
        else if (current !== shown)
            swapping.restart();
    }
    // a hot reload with a section open: just show it
    Component.onCompleted: if (current !== "") shown = current

    // the blocks: the section's children, one level into tall columns (so list rows arrive one by one)
    function collect(item, depth) {
        let out = [];
        for (const c of item.children) {
            if (!c.visible || c.width <= 0 || c.height <= 0)
                continue;
            if (depth < 1 && c.spacing !== undefined && c.children.length > 1 && c.height > 140)
                out = out.concat(collect(c, depth + 1));
            else
                out.push(c);
        }
        return out;
    }

    function clearOverlays() {
        for (const o of overlays)
            o.destroy();
        overlays = [];
    }

    // interrupted mid-build (close / switch): everything to its final state, stand-ins gone
    function finish() {
        clearOverlays();
        for (const b of blocks) {
            b.item.opacity = 1;
            b.tr.y = 0;
        }
        for (const a of atoms) {
            a.item.opacity = 1;
            a.item.scale = 1;
            a.ov = null;
            a.done = true;
        }
    }

    // lay out every row / column / grid now, innermost first: prepare() runs the moment the section loads, before
    // Qt's own layout pass, and every position would read 0 (the album cover sorted as the title - Mario 2026-10-26)
    function layoutAll(item) {
        for (const c of item.children)
            layoutAll(c);
        if (typeof item.forceLayout === "function")
            item.forceLayout();
    }

    function prepare() {
        const sec = loader.item;
        layoutAll(sec);
        clearOverlays();
        boxW = sec.width;
        blocks = collect(sec, 0).map(b => {
            const tr = Qt.createQmlObject("import QtQuick; Translate {}", b);
            b.transform = [tr];
            b.opacity = 0;
            return { item: b, tr: tr, y: b.mapToItem(sec, 0, 0).y, start: 0 };
        }).sort((a, b) => a.y - b.y);
        if (blocks.length)
            boxH = blocks[0].item.height;

        const list = [];
        const at = c => c.mapToItem(sec, 0, 0);
        for (let i = 1; i < blocks.length; i++) {
            const t0 = 220 + (i - 1) * 70; // the block lands
            blocks[i].start = t0;
            const texts = [];
            const walk = item => {
                for (const c of item.children) {
                    if (!c.visible || c.width <= 0 || c.height <= 0)
                        continue;
                    const isText = c.font !== undefined && c.text !== undefined;
                    const isRect = c.border !== undefined && c.radius !== undefined;
                    const isImage = c.fillMode !== undefined && c.source !== undefined && c.sourceSize !== undefined;
                    if (isImage) {
                        // pictures (album covers, the printer plate): fade + settle in as their frame's trace finishes
                        list.push({ item: c, kind: "image", start: t0 + 300, dur: 320 });
                        walk(c);
                    } else if (isText) {
                        texts.push(c);
                    } else if (isRect && c.border.width > 0 && c.width > 100 && c.height > 60) {
                        list.push({ item: c, kind: "trace", start: t0 + 60, dur: 420 });
                        walk(c);
                    } else if (c.children.length === 0 || c.children.every(k => k.width <= 0 || !k.visible)) {
                        const tiny = isRect && c.width < 34 && c.height < 34 && c.border.width > 0 && c.border.width < 1;
                        list.push({
                            item: c,
                            kind: tiny ? "flicker" : "pop",
                            start: t0 + 140 + (tiny ? Math.random() * 300 : at(c).x * 0.25),
                            dur: tiny ? 120 : 200
                        });
                    } else {
                        walk(c);
                    }
                }
            };
            walk(blocks[i].item);
            texts.sort((a, b) => at(a).y - at(b).y || at(a).x - at(b).x);
            texts.forEach((t, k) => {
                const big = t.font.pixelSize >= 60 && /\d/.test(t.text);
                list.push({ item: t, kind: big ? "roll" : "type", start: t0 + 300 + k * 30, dur: big ? 520 : 220 });
            });
        }
        list.forEach((a, k) => {
            a.i = k;
            if (a.kind !== "trace")
                a.item.opacity = 0;
        });
        atoms = list;
        total = list.reduce((m, a) => Math.max(m, a.start + a.dur), 600) + 40;
        clock = 0;
        if (slabR >= 1 && slabL === 0)
            reveal.restart(); // already covered (a swap)
        else
            opening.restart();
    }

    // an orange line running once around a framed shape's border, then gone
    function trace(a, p) {
        if (!a.ov) {
            const pos = a.item.mapToItem(stage, 0, 0);
            a.ov = Qt.createQmlObject("import QtQuick; Item { Rectangle { height: 2 } Rectangle { width: 2 } Rectangle { height: 2 } Rectangle { width: 2 } }", stage);
            a.ov.x = pos.x;
            a.ov.y = pos.y;
            a.ov.z = 11;
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

    // big numbers: a stand-in rolls random digits over the real one, then hands over
    function roll(a, p) {
        if (p >= 1) {
            drop(a);
            a.item.opacity = 1;
            return;
        }
        if (!a.ov) {
            const pos = a.item.mapToItem(stage, 0, 0);
            a.ov = Qt.createQmlObject("import QtQuick; Text {}", stage);
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
        // the title is there as soon as the slab starts pulling away
        if (blocks.length)
            blocks[0].item.opacity = 1;
        for (let i = 1; i < blocks.length; i++) {
            const p = Math.max(0, Math.min(1, (clock - blocks[i].start) / 260));
            const e = 1 - Math.pow(1 - p, 3);
            blocks[i].item.opacity = e;
            blocks[i].tr.y = -(1 - e) * 24;
        }
        for (const a of atoms) {
            if (a.done)
                continue;
            const p = Math.max(0, Math.min(1, (clock - a.start) / a.dur));
            if (p <= 0)
                continue;
            if (a.kind === "trace") {
                trace(a, p);
            } else if (a.kind === "roll") {
                roll(a, p);
            } else if (a.kind === "type") {
                // flicker on: hard blinks while it runs, then solid
                a.item.opacity = p >= 1 ? 1 : ((Math.floor(clock / 45) + a.i) % 3 === 0 ? 0.15 : 0.5 + p / 2);
                a.done = p >= 1;
            } else if (a.kind === "flicker") {
                a.item.opacity = p >= 1 || Math.random() < p ? 1 : 0;
                a.done = p >= 1;
            } else if (a.kind === "image") {
                const e = 1 - Math.pow(1 - p, 3);
                a.item.opacity = e;
                a.item.scale = 0.94 + 0.06 * e;
                a.done = p >= 1;
            } else { // pop
                const e = 1 - Math.pow(1 - p, 3);
                a.item.opacity = e;
                a.item.scale = 0.5 + 0.5 * e;
                a.done = p >= 1;
            }
        }
    }

    Loader {
        id: loader
        sourceComponent: stage.sections[stage.shown] ?? null
        onLoaded: stage.prepare()
    }

    Rectangle {
        x: stage.boxW * stage.slabL - 12
        y: -12
        width: stage.boxW * (stage.slabR - stage.slabL) + 24
        height: stage.boxH + 24
        visible: stage.slabR > stage.slabL
        color: GroundTheme.acc
        z: 10
    }

    SequentialAnimation {
        id: opening
        ScriptAction { script: { stage.slabL = 0; stage.slabR = 0; } }
        NumberAnimation { target: stage; property: "slabR"; to: 1; duration: 180; easing.type: Easing.InCubic }
        ScriptAction { script: reveal.restart() }
    }
    ParallelAnimation {
        id: reveal
        NumberAnimation { target: stage; property: "slabL"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
        NumberAnimation { target: stage; property: "clock"; from: 0; to: stage.total; duration: stage.total }
        onFinished: { stage.slabL = 0; stage.slabR = 0; }
    }
    SequentialAnimation {
        id: closing
        ScriptAction { script: { reveal.stop(); opening.stop(); stage.finish(); stage.slabL = 0; stage.slabR = 0; } }
        ParallelAnimation {
            NumberAnimation { target: stage; property: "slabR"; to: 1; duration: 150; easing.type: Easing.InCubic }
            NumberAnimation { target: loader; property: "opacity"; to: 0; duration: 150 }
        }
        ScriptAction { script: { stage.shown = ""; loader.opacity = 1; } }
        NumberAnimation { target: stage; property: "slabL"; to: 1; duration: 140; easing.type: Easing.OutCubic }
        ScriptAction { script: { stage.slabL = 0; stage.slabR = 0; } }
    }
    SequentialAnimation {
        id: swapping
        ScriptAction { script: { reveal.stop(); opening.stop(); stage.finish(); stage.slabL = 0; stage.slabR = 0; } }
        ParallelAnimation {
            NumberAnimation { target: stage; property: "slabR"; to: 1; duration: 150; easing.type: Easing.InCubic }
            NumberAnimation { target: loader; property: "opacity"; to: 0; duration: 150 }
        }
        ScriptAction { script: { loader.opacity = 1; stage.shown = stage.current; } } // loads under the slab -> prepare() -> reveal
    }
}
