// Felt's column: her tray's status, her switches (HA), her last line and a talk box - all through the Felt tray's
// session-bus API (org.clockmost.Felt: Status, LastLine, Say). The tray holds the felt-core credential; the shell
// never does (Mario 2026-10-25: "send through the tray").
// Motion (Mario 2026-10-26): sending squeezes your text up out of the box; while she thinks, her orange bar splits
// out of its box (halves up / down) and hazard stripes slide in, every other one from the other side (1st from above,
// 2nd from below ...), and crawl; her reply: the stripes leave the same way, the bar comes back, the line types on
// behind an orange block cursor - over the old line, like Insert on Windows, wiping whatever the new line doesn't
// reach (Mario 2026-10-26).
import QtQuick
import Quickshell.Io

Rectangle {
    id: root

    property string state: "CHECKING"
    property string lastLine: "…"
    property string lastMeta: ""
    property real lastAt: -1 // the line's time: a new value = a new line
    property bool thinking: false
    property real sentAt: 0
    property int typed: 0 // the overtype cursor's position
    property string oldLine: "" // what the new line types over
    readonly property var api: ["busctl", "--user", "--json=short"]
    readonly property var obj: ["org.clockmost.Felt", "/org/clockmost/Felt", "org.clockmost.Felt"]

    function say(text) {
        if (text.trim() === "")
            return;
        sayProc.command = ["busctl", "--user", "call"].concat(root.obj, ["Say", "s", text.trim()]);
        sayProc.running = true;
        root.sentAt = Date.now() / 1000;
        root.thinking = true;
        thinkTimeout.restart();
    }
    // she never answered (tray down, model busy): stop thinking after 2 min
    Timer { id: thinkTimeout; interval: 120000; onTriggered: root.thinking = false }

    // overtype, display only (lastLine / oldLine are never changed by it): the new line up to the cursor; where the
    // new line is shorter, the old characters it passed drawn transparent (wiped, nothing moves); the cursor; the old rest
    function overtype(n, cursorOn) {
        const nw = root.lastLine, old = root.oldLine;
        const wiped = old.slice(nw.length, Math.max(nw.length, Math.min(n, old.length)));
        const head = escaped(nw.slice(0, n)) + (wiped ? "<font color='transparent'>" + escaped(wiped) + "</font>" : "");
        return head + (cursorOn ? "<font color='" + GroundTheme.acc + "'>█</font>" : "") + escaped(old.slice(n));
    }

    function escaped(t) {
        return t.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }

    // polled: the tray emits no change signals yet; 3 s is plenty for a line on the desktop
    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statusProc.running = true;
            lineProc.running = true;
        }
    }
    Process {
        id: statusProc
        command: root.api.concat(["get-property"], root.obj, ["Status"])
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.state = JSON.parse(text).data.toUpperCase(); } catch (e) { root.state = "OFFLINE"; }
            }
        }
        onExited: code => { if (code !== 0) root.state = "OFFLINE"; }
    }
    Process {
        id: lineProc
        command: root.api.concat(["get-property"], root.obj, ["LastLine"])
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const l = JSON.parse(JSON.parse(text).data);
                    if (!l.text || l.at === root.lastAt) return;
                    const first = root.lastAt < 0;
                    root.lastAt = l.at;
                    root.oldLine = first ? "" : root.lastLine;
                    root.lastLine = l.text;
                    root.lastMeta = Qt.formatTime(new Date(l.at * 1000), "hh:mm") + "  ·  " + String(l.source).toUpperCase();
                    line.open = false;
                    if (first) {
                        root.typed = Math.max(l.text.length, root.oldLine.length); // there before the shell started: no show
                        return;
                    }
                    root.thinking = false;
                    thinkTimeout.stop();
                    typing.restart();
                } catch (e) {}
            }
        }
    }
    Process { id: sayProc }

    width: 532
    height: col.height + 12
    color: GroundTheme.bg

    // her HA switches, live and clickable (the FELT list section moved here - Mario 2026-10-25)
    component Chip: Rectangle {
        property string label
        property string entity
        readonly property bool on: HaClient.isOn(entity)
        width: t.implicitWidth + 16
        height: 24
        color: "transparent"
        border.width: 1
        border.color: on ? GroundTheme.ink : GroundTheme.line
        Text { id: t; anchors.centerIn: parent; text: parent.label; color: parent.on ? GroundTheme.ink : GroundTheme.ink2; font.family: GroundTheme.mono; font.pixelSize: 10; font.letterSpacing: 2 }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: HaClient.toggle(parent.entity) }
    }

    Column {
        id: col
        x: 12
        width: 520
        spacing: 0

        Item {
            width: parent.width
            height: 66
            Text {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10
                text: "FELT"
                color: GroundTheme.ink
                font.family: GroundTheme.display
                font.pixelSize: 64
                font.weight: Font.Black
                font.variableAxes: { "wdth": 70, "wght": 900 }
            }
            Row {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 16
                spacing: 8
                Rectangle { width: 10; height: 10; radius: 5; color: GroundTheme.acc; anchors.verticalCenter: parent.verticalCenter }
                Text { text: root.state; color: GroundTheme.acc; font.family: GroundTheme.mono; font.pixelSize: 11; font.letterSpacing: 3 }
            }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 2; color: GroundTheme.ink }
        }

        Item { width: 1; height: 12 }
        Item {
            width: parent.width
            height: 24
            Row { spacing: 6; Chip { label: "QUIET"; entity: "switch.felt_quiet" } Chip { label: "HIDDEN"; entity: "switch.felt_hidden" } Chip { label: "DJ"; entity: "switch.felt_dj_mode" } }

        }

        Item { width: 1; height: 26 }
        Item {
            id: lineBox
            width: parent.width
            // one fixed size (Mario 2026-10-26): 6 lines of her text + the meta line, whatever she says
            height: line.lineCount > 6 && line.open ? quote.height : 6 * 26 + 12 + 14

            // the bar: solid halves, or hazard halves while she thinks; both slide in and out of this rail
            Item {
                id: rail
                width: 10
                height: parent.height
                clip: true
                property real solidOut: root.thinking ? 1 : 0 // 0 = in place .. 1 = out of the box
                property real hazardIn: root.thinking ? 1 : 0
                Behavior on solidOut { NumberAnimation { duration: root.thinking ? 260 : 480; easing.type: root.thinking ? Easing.InCubic : Easing.OutQuart } }
                Behavior on hazardIn {
                    SequentialAnimation {
                        PauseAnimation { duration: root.thinking ? 200 : 0 }
                        NumberAnimation { duration: root.thinking ? 480 : 260; easing.type: root.thinking ? Easing.OutQuart : Easing.InCubic }
                    }
                }
                Rectangle { width: 4; height: rail.height / 2; y: -rail.solidOut * rail.height / 2; color: GroundTheme.acc }
                Rectangle { width: 4; height: rail.height / 2; y: rail.height / 2 + rail.solidOut * rail.height / 2; color: GroundTheme.acc }
                // hazard stripes: odd ones arrive from above, even ones from below; they crawl down while she thinks
                property real crawl: 0
                NumberAnimation on crawl { from: 0; to: 14; duration: 420; loops: Animation.Infinite; running: root.thinking || rail.hazardIn > 0 }
                Repeater {
                    model: Math.ceil(rail.height / 14) + 2
                    Rectangle {
                        required property int index
                        x: -3
                        y: (index - 1) * 14 + rail.crawl + (1 - rail.hazardIn) * (index % 2 ? rail.height + 28 : -(rail.height + 28))
                        width: 16
                        height: 8
                        rotation: -45
                        color: GroundTheme.acc
                        visible: rail.hazardIn > 0
                    }
                }
            }

            Column {
                id: quote
                x: 22
                width: parent.width - 22
                spacing: 12
                opacity: root.thinking ? 0.35 : 1
                Behavior on opacity { NumberAnimation { duration: 180 } }
                Text {
                    id: line
                    property bool open: false // click: the whole line when it's longer than the box
                    width: parent.width
                    height: open ? implicitHeight : Math.min(implicitHeight, 6 * 26)
                    textFormat: Text.StyledText
                    text: root.overtype(root.typed, cursor.on)
                    wrapMode: Text.WordWrap
                    maximumLineCount: open ? 40 : 6
                    elide: Text.ElideRight
                    color: GroundTheme.ink
                    font.family: GroundTheme.display
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                    font.variableAxes: { "wght": 600 }
                    lineHeightMode: Text.FixedHeight
                    lineHeight: 26
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: line.open = !line.open }
                }
                RollText { value: root.lastMeta; color: GroundTheme.ink2; font.family: GroundTheme.mono; font.pixelSize: 10; font.letterSpacing: 3 }
            }

            // typing: ~30 characters a second over the longer of new / old (capped at 4 s), then the cursor blinks
            // twice and goes; the old line is dropped once it's fully overwritten
            SequentialAnimation {
                id: typing
                ScriptAction { script: { root.typed = 0; cursor.on = true; } }
                PauseAnimation { duration: 260 } // the hazard leaves first
                NumberAnimation {
                    target: root
                    property: "typed"
                    from: 0
                    to: Math.max(root.lastLine.length, root.oldLine.length)
                    duration: Math.min(4000, Math.max(root.lastLine.length, root.oldLine.length) * 33)
                }
                ScriptAction { script: { root.oldLine = ""; blink.restart(); } }
            }
            QtObject { id: cursor; property bool on: false }
            SequentialAnimation {
                id: blink
                loops: 2
                ScriptAction { script: cursor.on = false }
                PauseAnimation { duration: 220 }
                ScriptAction { script: cursor.on = true }
                PauseAnimation { duration: 220 }
                onFinished: cursor.on = false
            }
        }

        Item { width: 1; height: 22 }
        Rectangle {
            width: parent.width
            height: 48
            color: "transparent"
            border.width: 1.5
            border.color: input.activeFocus ? GroundTheme.acc : GroundTheme.ink
            // the talk box: type, Enter = sent to her through the tray (she answers out loud)
            TextInput {
                id: input
                x: 14
                width: parent.width - 110
                anchors.verticalCenter: parent.verticalCenter
                color: GroundTheme.ink
                font.family: GroundTheme.mono
                font.pixelSize: 13
                selectByMouse: true
                clip: true
                cursorDelegate: Rectangle { width: 9; height: 18; color: GroundTheme.acc; visible: input.activeFocus }
                onAccepted: {
                    if (text.trim() === "")
                        return;
                    ghost.text = text;
                    sent.restart();
                    root.say(text);
                    text = "";
                }
                Keys.onEscapePressed: { text = ""; focus = false; }
            }
            // sent: the box flashes orange, your text squeezes narrow and shoots up out of it
            Rectangle {
                id: flash
                anchors.fill: parent
                color: GroundTheme.acc
                opacity: 0
            }
            Text {
                id: ghost
                x: 14
                y: (parent.height - height) / 2
                opacity: 0
                color: GroundTheme.ink
                font.family: GroundTheme.mono
                font.pixelSize: 13
                transform: Scale { id: squeeze; xScale: 1 }
            }
            ParallelAnimation {
                id: sent
                SequentialAnimation {
                    NumberAnimation { target: flash; property: "opacity"; from: 0.9; to: 0; duration: 220 }
                }
                SequentialAnimation {
                    ScriptAction { script: { ghost.opacity = 1; ghost.y = (ghost.parent.height - ghost.height) / 2; squeeze.xScale = 1; } }
                    NumberAnimation { target: squeeze; property: "xScale"; to: 0.25; duration: 140; easing.type: Easing.InCubic }
                    ParallelAnimation {
                        NumberAnimation { target: ghost; property: "y"; to: -70; duration: 260; easing.type: Easing.InCubic }
                        NumberAnimation { target: ghost; property: "opacity"; to: 0; duration: 260; easing.type: Easing.InCubic }
                    }
                }
            }
            Row {
                x: 14
                visible: input.text === "" && !input.activeFocus
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                Text { text: "SAY SOMETHING"; color: GroundTheme.ink2; font.family: GroundTheme.mono; font.pixelSize: 12; font.letterSpacing: 3; anchors.verticalCenter: parent.verticalCenter }
                Rectangle { width: 9; height: 18; color: GroundTheme.acc; anchors.verticalCenter: parent.verticalCenter }
            }
            Rectangle {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                width: kbd.implicitWidth + 12
                height: 20
                color: GroundTheme.ink
                Text { id: kbd; anchors.centerIn: parent; text: "META+F"; color: GroundTheme.bg; font.family: GroundTheme.mono; font.pixelSize: 10 }
            }
        }
    }
}
