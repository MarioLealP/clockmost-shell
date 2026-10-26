// Felt's column: her tray's status, her switches (HA), her last line and a talk box - all through the Felt tray's
// session-bus API (org.clockmost.Felt: Status, LastLine, Say). The tray holds the felt-core credential; the shell
// never does (Mario 2026-10-25: "send through the tray").
import QtQuick
import Quickshell.Io

Rectangle {
    id: root

    property string state: "CHECKING"
    property string lastLine: "…"
    property string lastMeta: ""
    readonly property var api: ["busctl", "--user", "--json=short"]
    readonly property var obj: ["org.clockmost.Felt", "/org/clockmost/Felt", "org.clockmost.Felt"]

    function say(text) {
        if (text.trim() === "")
            return;
        sayProc.command = ["busctl", "--user", "call"].concat(root.obj, ["Say", "s", text.trim()]);
        sayProc.running = true;
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
                    if (!l.text) return;
                    root.lastLine = l.text;
                    root.lastMeta = Qt.formatTime(new Date(l.at * 1000), "hh:mm") + "  ·  " + String(l.source).toUpperCase();
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
            width: parent.width
            height: quote.height
            Rectangle { width: 4; height: parent.height; color: GroundTheme.acc }
            Column {
                id: quote
                x: 22
                width: parent.width - 22
                spacing: 12
                Text {
                    width: parent.width
                    text: root.lastLine
                    wrapMode: Text.WordWrap
                    color: GroundTheme.ink
                    font.family: GroundTheme.display
                    font.pixelSize: 30
                    font.weight: Font.DemiBold
                    font.variableAxes: { "wght": 600 }
                    lineHeight: 1.18
                }
                Text { text: root.lastMeta; color: GroundTheme.ink2; font.family: GroundTheme.mono; font.pixelSize: 10; font.letterSpacing: 3 }
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
                    root.say(text);
                    text = "";
                }
                Keys.onEscapePressed: { text = ""; focus = false; }
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
