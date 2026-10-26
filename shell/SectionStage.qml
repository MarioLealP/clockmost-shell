// The HA section's place on the ground and its motion (option 1, Mario 2026-10-26: "do the sweep for the title, then
// drop the content"): a solid orange slab - a transitional piece, never part of the final UI - wipes across the title
// row and pulls away the other way, uncovering it; then the rest drops into place from above, one block after another
// (35 ms apart, falling 24 px). Close: the content fades while the slab wipes back over the title, the section unloads
// under it, the slab leaves. Switching: the same cover, swap, reveal. Opening waits for the line: lineAway().
import QtQuick

Item {
    id: stage

    property var sections: ({}) // name -> Component
    readonly property string current: HaSections.current
    property string shown: ""
    property real slabL: 0 // the slab's edges, 0..1 of the box
    property real slabR: 0
    property real clock: 0 // the cascade's time, ms
    property real boxW: 560
    property real boxH: 64 // the title row
    property var blocks: []

    function lineAway() {
        if (current !== "" && shown === "")
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

    // the blocks to cascade: the section's children, one level into tall columns (so list rows arrive one by one)
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

    function prepare() {
        const sec = loader.item;
        boxW = sec.width;
        blocks = collect(sec, 0).map(b => {
            const tr = Qt.createQmlObject("import QtQuick; Translate {}", b);
            b.transform = [tr];
            b.opacity = 0;
            return { item: b, tr: tr, y: b.mapToItem(sec, 0, 0).y };
        }).sort((a, b) => a.y - b.y);
        if (blocks.length)
            boxH = blocks[0].item.height;
        clock = 0;
        if (slabR >= 1 && slabL === 0)
            reveal.restart(); // already covered (a swap)
        else
            opening.restart();
    }

    onClockChanged: {
        // the title is there as soon as the slab starts pulling away; the rest drops once it's gone (220 ms)
        if (blocks.length)
            blocks[0].item.opacity = 1;
        for (let i = 1; i < blocks.length; i++) {
            const p = Math.max(0, Math.min(1, (clock - 220 - (i - 1) * 35) / 260));
            const e = 1 - Math.pow(1 - p, 3);
            blocks[i].item.opacity = e;
            blocks[i].tr.y = -(1 - e) * 24;
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
        NumberAnimation { target: stage; property: "clock"; from: 0; to: stage.blocks.length * 35 + 480; duration: stage.blocks.length * 35 + 480 }
        onFinished: { stage.slabL = 0; stage.slabR = 0; }
    }
    SequentialAnimation {
        id: closing
        ScriptAction { script: { reveal.stop(); opening.stop(); stage.slabL = 0; stage.slabR = 0; } }
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
        ScriptAction { script: { reveal.stop(); opening.stop(); stage.slabL = 0; stage.slabR = 0; } }
        ParallelAnimation {
            NumberAnimation { target: stage; property: "slabR"; to: 1; duration: 150; easing.type: Easing.InCubic }
            NumberAnimation { target: loader; property: "opacity"; to: 0; duration: 150 }
        }
        ScriptAction { script: { loader.opacity = 1; stage.shown = stage.current; } } // loads under the slab -> prepare() -> reveal
    }
}
