// The HA section's place on the ground and its motion (option 1, Mario 2026-10-26): a solid orange slab - a
// transitional piece, never part of the final UI - wipes across the section's box and pulls away the other way,
// uncovering it while the blocks cascade in (header first, each next one 35 ms later, rising 14 px). Close: the slab
// wipes back over, the section unloads under it, the slab leaves. Switching sections: cover, swap under the slab,
// reveal. Opening waits for the line: lineAway() (GroundLine.away) is the cue.
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
    property real boxH: 400
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
        boxH = sec.height;
        blocks = collect(sec, 0).map(b => {
            const tr = Qt.createQmlObject("import QtQuick; Translate {}", b);
            b.transform = [tr];
            b.opacity = 0;
            return { item: b, tr: tr, y: b.mapToItem(sec, 0, 0).y };
        }).sort((a, b) => a.y - b.y);
        clock = 0;
        if (slabR >= 1 && slabL === 0)
            reveal.restart(); // already covered (a swap)
        else
            opening.restart();
    }

    onClockChanged: {
        for (let i = 0; i < blocks.length; i++) {
            const p = Math.max(0, Math.min(1, (clock - i * 35) / 240));
            const e = 1 - Math.pow(1 - p, 3);
            blocks[i].item.opacity = e;
            blocks[i].tr.y = (1 - e) * 14;
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
        NumberAnimation { target: stage; property: "clock"; from: 0; to: stage.blocks.length * 35 + 260; duration: stage.blocks.length * 35 + 260 }
        onFinished: { stage.slabL = 0; stage.slabR = 0; }
    }
    SequentialAnimation {
        id: closing
        ScriptAction { script: { reveal.stop(); opening.stop(); stage.slabL = 0; stage.slabR = 0; } }
        NumberAnimation { target: stage; property: "slabR"; to: 1; duration: 150; easing.type: Easing.InCubic }
        ScriptAction { script: stage.shown = "" }
        NumberAnimation { target: stage; property: "slabL"; to: 1; duration: 140; easing.type: Easing.OutCubic }
        ScriptAction { script: { stage.slabL = 0; stage.slabR = 0; } }
    }
    SequentialAnimation {
        id: swapping
        ScriptAction { script: { reveal.stop(); opening.stop(); stage.slabL = 0; stage.slabR = 0; } }
        NumberAnimation { target: stage; property: "slabR"; to: 1; duration: 150; easing.type: Easing.InCubic }
        ScriptAction { script: stage.shown = stage.current } // loads under the slab -> prepare() -> reveal
    }
}
