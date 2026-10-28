// The clockmost login (desktop-environment-v2 stage 4). One user, no choices: a loading screen while the tang server
// on the home LAN comes up, then a no-password login that the tang gate (pam_exec, /usr/lib/clockmost-shell/tang-gate)
// checks for real. No tang within the cutoff, or the gate says no: the loading turns into the password field. Either
// way a login that goes through moves on to phase 2 (the desktop loading).
//
// Motion (Mario 2026-10-27, his sketch): two thick strokes come in along a diagonal, one from the top, one from the
// bottom, meet in the middle as one slanted line, and shrink into a block; the block turns a quarter per lap while it
// waits (every change starts at a lap's end), then
//   tang -> it grows back into a line, turning on to a "\" diagonal, splits, and the strokes leave along it
//   no tang -> it squares up and flattens into the orange mark of a rule; the hairline grows out, the field rises
//   field + Enter -> it all pulls back into the block, which turns once full circle, then the same exit.
// Unhurried on purpose (Mario: "a tad slower"): the intro alone covers most of the ~3 s tang needs at boot.
import QtQuick

Rectangle {
    id: root

    readonly property color bg: "#1a1a18"
    readonly property color ink: "#e8e6df"
    readonly property color ink2: "#8a8881"
    readonly property color line: "#3a3a37"
    readonly property color acc: "#ff5f1f"
    readonly property string mono: "JetBrains Mono"
    readonly property string display: archivo.status === FontLoader.Ready ? archivo.name : "sans-serif"
    FontLoader {
        id: archivo
        source: "file:///usr/share/clockmost-shell/assets/fonts/Archivo-Variable.ttf"
    }

    readonly property string user: userModel.lastUser || userModel.data(userModel.index(0, 0), Qt.UserRole + 1)
    readonly property int session: sessionModel.lastIndex
    // any of these answering will do (the gate's sealed file opens with either: clevis sss t=1)
    readonly property var tangUrls: String(config.tangUrls || "").split(",").map(u => u.trim()).filter(u => u !== "")

    // what the next lap's end does: tang answered, or the cutoff passed
    property bool tangUp: false
    property bool wantField: false
    property bool inField: false
    property bool wrong: false
    property string pw: ""

    // the bar: two strokes of length `half` either side of the centre, `reach` apart from it, `thick` wide, turned by
    // `bar.rotation` (the lap's quarter turn on top: `spinner`)
    readonly property real slant: -60 // the entrance's diagonal: "/" (Qt turns clockwise)
    readonly property real exitSlant: 42 // the exit's: it keeps turning past flat into a "\" (Mario: "60º more")
    property real half: 300
    property real reach: Math.hypot(width, height) / 2 + 40
    property real rule: 0 // the field's hairline, half its width
    property real fieldP: 0 // 0 = field hidden .. 1 = shown
    readonly property real bold: 36
    property real thick: bold

    color: bg

    // how far from the centre to the screen's edge along a line at `deg`
    function edgeAlong(deg) {
        const r = deg * Math.PI / 180;
        return Math.min(width / 2 / Math.max(Math.abs(Math.cos(r)), 1e-6), height / 2 / Math.max(Math.abs(Math.sin(r)), 1e-6));
    }

    function lapEnd() {
        if (tangUp) {
            pw = "";
            exit.start();
        } else if (wantField) {
            toField.start();
        } else {
            pulse.start();
        }
    }
    function submit() {
        if (pass.text === "" || !inField)
            return;
        pw = pass.text;
        inField = false;
        fromField.start();
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            // the gate said no (e.g. after a logout) or a wrong password: back to a bar, then the field
            root.wrong = root.pw !== "";
            root.pw = "";
            pass.text = "";
            root.tangUp = false;
            root.color = root.bg;
            root.reach = 0;
            root.half = root.bold / 2;
            root.thick = root.bold;
            bar.rotation = 0;
            spinner.rotation = 0;
            bar.visible = true;
            toField.start();
        }
    }

    // ask the tangs every half second until one answers (or the field is up)
    Timer {
        interval: 500
        repeat: true
        triggeredOnStart: true
        running: !root.tangUp && !root.wantField && root.tangUrls.length > 0
        onTriggered: {
            for (const url of root.tangUrls) {
                const x = new XMLHttpRequest();
                x.onreadystatechange = () => {
                    if (x.readyState === XMLHttpRequest.DONE && x.status === 200 && !root.wantField)
                        root.tangUp = true;
                };
                x.open("GET", url + "/adv");
                x.send();
            }
        }
    }
    Timer {
        interval: (Number(config.cutoff) || 9) * 1000
        running: !root.tangUp
        onTriggered: root.wantField = true
    }
    Component.onCompleted: {
        if (tangUrls.length === 0)
            wantField = true;
        intro.start();
    }

    // ---- motion ----

    SequentialAnimation {
        id: intro
        PauseAnimation { duration: 300 }
        NumberAnimation { target: root; property: "reach"; to: 0; duration: 1100; easing.type: Easing.InOutQuart }
        NumberAnimation { target: root; property: "half"; to: root.bold / 2; duration: 750; easing.type: Easing.InOutCubic }
        ScriptAction { script: root.lapEnd() }
    }
    SequentialAnimation {
        id: pulse
        // a square turned a quarter looks the same: back to 0 at the lap's end, no jump
        NumberAnimation { target: spinner; property: "rotation"; from: 0; to: 90; duration: 700; easing.type: Easing.InOutCubic }
        ScriptAction { script: spinner.rotation = 0 }
        // later, not here: start() on the pulse while its own last step runs is ignored (the loop froze after a lap)
        ScriptAction { script: Qt.callLater(root.lapEnd) }
    }
    SequentialAnimation {
        id: exit
        // it turns on to the exit's diagonal while it grows, then the strokes leave along it
        ParallelAnimation {
            NumberAnimation { target: bar; property: "rotation"; to: root.exitSlant; duration: 700; easing.type: Easing.InOutCubic }
            NumberAnimation { target: root; property: "half"; to: 300; duration: 700; easing.type: Easing.InOutCubic }
        }
        NumberAnimation { target: root; property: "reach"; to: root.edgeAlong(root.exitSlant) + 40; duration: 1000; easing.type: Easing.InOutQuart }
        // then dim to black: the two KWins' handover blanks the screens for a few frames, so the sequence takes that
        // beat on purpose (the splash brightens back up from black)
        ColorAnimation { target: root; property: "color"; to: "#000000"; duration: 280; easing.type: Easing.InQuad }
        // every screen plays it; the no-password login goes in from the primary screen only (each screen's copy asked
        // at once on the first real boot - SDDM dropped the spare: "Existing authentication ongoing"). A typed
        // password goes in from the screen it was typed on.
        ScriptAction { script: if (root.pw !== "" || primaryScreen) sddm.login(root.user, root.pw, root.session) }
    }
    SequentialAnimation {
        id: toField
        NumberAnimation { target: bar; property: "rotation"; to: 0; duration: 450; easing.type: Easing.OutCubic }
        ParallelAnimation {
            NumberAnimation { target: root; property: "half"; to: 116; duration: 400; easing.type: Easing.OutCubic }
            NumberAnimation { target: root; property: "thick"; to: 6; duration: 400; easing.type: Easing.OutCubic }
        }
        NumberAnimation { target: root; property: "rule"; from: 116; to: 600; duration: 520; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "fieldP"; to: 1; duration: 420; easing.type: Easing.OutCubic }
        ScriptAction { script: { root.inField = true; pass.forceActiveFocus(); } }
    }
    SequentialAnimation {
        id: fromField
        NumberAnimation { target: root; property: "fieldP"; to: 0; duration: 180; easing.type: Easing.InCubic }
        NumberAnimation { target: root; property: "rule"; to: 116; duration: 240; easing.type: Easing.InCubic }
        ScriptAction { script: root.rule = 0 }
        ParallelAnimation {
            NumberAnimation { target: root; property: "half"; to: root.bold / 2; duration: 320; easing.type: Easing.InOutCubic }
            NumberAnimation { target: root; property: "thick"; to: root.bold; duration: 320; easing.type: Easing.InOutCubic }
        }
        // the password went in: one full turn of the block (Mario), landing on the exit's diagonal so the exit's own
        // turn has nothing left to do ("it does a tiny slow spin, remove that")
        NumberAnimation { target: spinner; property: "rotation"; from: 0; to: 360 + root.exitSlant; duration: 900; easing.type: Easing.InOutCubic }
        ScriptAction { script: { bar.rotation = root.exitSlant; spinner.rotation = 0; exit.start(); } }
    }

    // ---- the pieces ----

    // the field's hairline (under the bar, which is its orange mark)
    Rectangle {
        visible: root.rule > 0
        x: root.width / 2 - root.rule
        y: root.height / 2 - height / 2
        width: root.rule * 2
        height: 1
        color: root.line
    }

    Item {
        id: bar
        x: root.width / 2
        y: root.height / 2
        rotation: root.slant
        Item {
            id: spinner
        Rectangle {
            x: -root.reach - root.half
            y: -root.thick / 2
            width: root.half
            height: root.thick
            color: root.acc
        }
        Rectangle {
            x: root.reach
            y: -root.thick / 2
            width: root.half
            height: root.thick
            color: root.acc
        }
        }
    }

    // the field: › PASSWORD▌ above the rule, rising out of it; the hint under it
    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height / 2 - 18 - 104
        width: head.width
        height: 104
        clip: true
        visible: root.fieldP > 0
        Row {
            id: head
            y: (1 - root.fieldP) * 110
            height: 104
            spacing: 18
            Text {
                anchors.baseline: shown.baseline
                text: "›"
                color: root.acc
                font.family: root.display
                font.weight: Font.Black
                font.pixelSize: 72
            }
            Text {
                id: shown
                anchors.verticalCenter: parent.verticalCenter
                text: pass.text === "" ? "PASSWORD" : "•".repeat(pass.text.length)
                color: pass.text === "" ? "#2e2e2b" : root.ink
                font.family: root.display
                font.weight: Font.Black
                font.variableAxes: { "wdth": 70, "wght": 900 }
                font.pixelSize: 104
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 14
                height: 84
                color: root.acc
                transform: Translate { x: -12 }
            }
        }
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height / 2 + 28
        opacity: root.fieldP
        text: root.wrong ? "WRONG PASSWORD" : "HOME NOT FOUND · TYPE YOUR PASSWORD"
        color: root.wrong ? root.acc : root.ink2
        font.family: root.mono
        font.pixelSize: 12
        font.letterSpacing: 3
    }

    TextInput {
        id: pass
        width: 1
        height: 1
        opacity: 0
        echoMode: TextInput.Password
        onTextChanged: if (text !== "") root.wrong = false
        Keys.onReturnPressed: root.submit()
        Keys.onEnterPressed: root.submit()
    }
}
