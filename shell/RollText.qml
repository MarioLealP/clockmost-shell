// Text that rolls when its value changes: each character that changed runs through random characters of its kind
// (digit / letter) and settles, left to right, in ~0.5 s (the motion language's number roll - the clock, the date,
// the weather). delay staggers rolls that happen together (the date stack at midnight). The first value just shows.
import QtQuick

Text {
    id: root

    property string value
    property int delay: 0
    property int duration: 520
    property string from: ""
    property string prev: ""
    property bool ready: false
    property real p: 1 // 0 = rolling starts .. 1 = settled

    function render(p, value) {
        if (p >= 1)
            return value;
        let out = "";
        for (let i = 0; i < value.length; i++) {
            const c = value[i];
            const settle = 0.4 + 0.6 * (i + 1) / value.length;
            if (c === root.from[i] || p >= settle || !/[0-9A-Za-z]/.test(c))
                out += c;
            else if (/[0-9]/.test(c))
                out += String(Math.floor(Math.random() * 10));
            else
                out += String.fromCharCode(65 + Math.floor(Math.random() * 26));
        }
        return out;
    }

    text: render(p, value)

    onValueChanged: {
        from = prev;
        prev = value;
        if (ready)
            roll.restart();
    }
    Component.onCompleted: {
        prev = value;
        ready = true;
    }

    SequentialAnimation {
        id: roll
        ScriptAction { script: root.p = 0 }
        PauseAnimation { duration: root.delay }
        NumberAnimation { target: root; property: "p"; from: 0; to: 1; duration: root.duration }
    }
}
