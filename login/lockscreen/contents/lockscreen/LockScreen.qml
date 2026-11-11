// The clockmost lock screen (desktop-environment-v2 item 15). kscreenlocker_greet loads this from the Plasma/Shell
// package org.clockmost.lock when KWin runs with PLASMA_DEFAULT_SHELL=org.clockmost.lock (a drop-in on
// plasma-kwin_wayland.service - plasmashell keeps its own shell). Same pieces and motion as the login
// (../../sddm-theme/Main.qml), quicker, because a lock screen is met many times a day:
//   lock -> the two strokes come in along the diagonal and shrink into the orange block, which turns a quarter per lap
//   key or mouse -> at a lap's end the block flattens into the field's orange mark, the hairline grows, the field rises
//   Enter -> it pulls back into the block, which turns while the password is checked; wrong -> back to the field
//   unlocked (password, or a touch on the YubiKey: /etc/pam.d/kde asks the key first) -> the strokes leave, quit.
// PAM talks through `authenticator` (org.kde.kscreenlocker): the key's "Please touch the device" comes in as
// infoMessage, the password prompt as promptForSecret.
import QtQuick

Rectangle {
    id: root

    // read by kscreenlocker_greet
    property bool debug: false
    property bool viewVisible: false
    property string notification
    signal clearPassword()
    signal notificationRepeated()

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

    // the login was drawn for 1440p; smaller screens (Brigid's 1080p) scale it down
    readonly property real s: Math.max(0.55, Math.min(1, height / 1440))

    property bool wantField: false // a key or the mouse moved: show the field at the next lap's end
    property bool inField: false
    property bool checking: false // a password went in, waiting for PAM
    property bool done: false // PAM said yes: leave at the next lap's end
    property bool keyAsks: false // pam_u2f is waiting for a touch
    property bool wrong: false
    property string pending: "" // typed while PAM was still busy (pamTimeout)

    readonly property real slant: -60
    readonly property real exitSlant: 42
    property real half: 300 * s
    property real reach: Math.hypot(width, height) / 2 + 40
    property real rule: 0
    property real fieldP: 0
    readonly property real bold: 36 * s
    property real thick: bold

    color: bg

    function edgeAlong(deg) {
        const r = deg * Math.PI / 180;
        return Math.min(width / 2 / Math.max(Math.abs(Math.cos(r)), 1e-6), height / 2 / Math.max(Math.abs(Math.sin(r)), 1e-6));
    }

    function lapEnd() {
        if (done)
            inField ? fromField.start() : exit.start();
        else if (wantField && !inField && !checking)
            toField.start();
        else if (!inField)
            pulse.start();
    }
    function wake() {
        if (!wantField && !done)
            wantField = true;
        pass.forceActiveFocus();
    }
    function submit() {
        if (pass.text === "" || !inField)
            return;
        const pw = pass.text;
        pass.text = "";
        checking = true;
        wantField = false;
        if (authenticator.pamTimeout)
            pending = pw;
        else
            authenticator.respond(pw);
        fromField.start();
    }

    Connections {
        target: authenticator
        function onSucceeded() {
            authenticator.stopAuthenticating();
            root.done = true;
            root.keyAsks = false;
            // nothing running (the field is up and idle): leave now, else the running step's end does it
            if (root.inField && !fromField.running && !toField.running)
                fromField.start();
        }
        function onFailed(kind) {
            if (kind !== 0) // the noninteractive authenticators (fingerprint, smartcard)
                return;
            root.checking = false;
            root.wrong = true;
            root.wantField = true;
            authenticator.startAuthenticating();
        }
        function onInfoMessageChanged() {
            if (/touch/i.test(authenticator.infoMessage))
                root.keyAsks = true;
        }
        function onPamTimeoutChanged() {
            if (!authenticator.pamTimeout && root.pending !== "") {
                authenticator.respond(root.pending);
                root.pending = "";
            }
        }
    }
    onClearPassword: pass.text = ""

    // keep PAM listening the whole time, so a touch on the key unlocks without touching anything else first
    Timer {
        interval: 1000
        repeat: true
        running: !authenticator.unlocked && !root.done
        onTriggered: authenticator.startAuthenticating()
    }
    Component.onCompleted: {
        authenticator.startAuthenticating();
        pass.forceActiveFocus();
        intro.start();
    }

    // ---- motion ----

    SequentialAnimation {
        id: intro
        NumberAnimation { target: root; property: "reach"; to: 0; duration: 650; easing.type: Easing.InOutQuart }
        NumberAnimation { target: root; property: "half"; to: root.bold / 2; duration: 450; easing.type: Easing.InOutCubic }
        ScriptAction { script: root.lapEnd() }
    }
    SequentialAnimation {
        id: pulse
        NumberAnimation { target: spinner; property: "rotation"; from: 0; to: 90; duration: root.keyAsks ? 450 : 900; easing.type: Easing.InOutCubic }
        ScriptAction { script: spinner.rotation = 0 }
        ScriptAction { script: Qt.callLater(root.lapEnd) }
    }
    SequentialAnimation {
        id: exit
        ParallelAnimation {
            NumberAnimation { target: bar; property: "rotation"; to: root.exitSlant; duration: 380; easing.type: Easing.InOutCubic }
            NumberAnimation { target: root; property: "half"; to: 300 * root.s; duration: 380; easing.type: Easing.InOutCubic }
        }
        NumberAnimation { target: root; property: "reach"; to: root.edgeAlong(root.exitSlant) + 40; duration: 520; easing.type: Easing.InQuart }
        ScriptAction { script: Qt.quit() }
    }
    SequentialAnimation {
        id: toField
        NumberAnimation { target: bar; property: "rotation"; to: 0; duration: 300; easing.type: Easing.OutCubic }
        ParallelAnimation {
            NumberAnimation { target: root; property: "half"; to: 116 * root.s; duration: 280; easing.type: Easing.OutCubic }
            NumberAnimation { target: root; property: "thick"; to: 6 * root.s; duration: 280; easing.type: Easing.OutCubic }
        }
        NumberAnimation { target: root; property: "rule"; from: 116 * root.s; to: 600 * root.s; duration: 360; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "fieldP"; to: 1; duration: 300; easing.type: Easing.OutCubic }
        ScriptAction { script: { root.inField = true; pass.forceActiveFocus(); if (root.done) fromField.start(); } }
    }
    SequentialAnimation {
        id: fromField
        ScriptAction { script: root.inField = false }
        NumberAnimation { target: root; property: "fieldP"; to: 0; duration: 140; easing.type: Easing.InCubic }
        NumberAnimation { target: root; property: "rule"; to: 116 * root.s; duration: 180; easing.type: Easing.InCubic }
        ScriptAction { script: root.rule = 0 }
        ParallelAnimation {
            NumberAnimation { target: root; property: "half"; to: root.bold / 2; duration: 240; easing.type: Easing.InOutCubic }
            NumberAnimation { target: root; property: "thick"; to: root.bold; duration: 240; easing.type: Easing.InOutCubic }
        }
        // one full turn while the password is checked (the login's turn, shorter)
        NumberAnimation { target: spinner; property: "rotation"; from: 0; to: 360; duration: 600; easing.type: Easing.InOutCubic }
        ScriptAction { script: { spinner.rotation = 0; Qt.callLater(root.lapEnd); } }
    }

    // ---- the pieces ----

    // a key or the mouse wakes the field; the cursor stays hidden until the mouse moves
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        property bool moved: false
        cursorShape: moved ? Qt.ArrowCursor : Qt.BlankCursor
        property point last: Qt.point(-1, -1)
        onPositionChanged: m => {
            // the first event is just where the pointer already was
            if (last.x >= 0 && (Math.abs(m.x - last.x) > 2 || Math.abs(m.y - last.y) > 2)) {
                moved = true;
                root.wake();
            }
            last = Qt.point(m.x, m.y);
        }
        onPressed: { moved = true; root.wake(); }
    }

    // LOCKED · time, top left, like the shell's own labels
    Text {
        x: 48 * root.s
        y: 40 * root.s
        text: "LOCKED · " + Qt.formatTime(clock.now, "HH:mm")
        color: root.ink2
        font.family: root.mono
        font.pixelSize: 13
        font.letterSpacing: 3
        Timer {
            id: clock
            property date now: new Date()
            interval: 1000
            repeat: true
            running: true
            onTriggered: now = new Date()
        }
    }

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

    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height / 2 - 18 * root.s - height
        width: head.width
        height: 104 * root.s
        clip: true
        visible: root.fieldP > 0
        Row {
            id: head
            y: (1 - root.fieldP) * 110 * root.s
            height: 104 * root.s
            spacing: 18 * root.s
            Text {
                anchors.baseline: shown.baseline
                text: "›"
                color: root.acc
                font.family: root.display
                font.weight: Font.Black
                font.pixelSize: 72 * root.s
            }
            Text {
                id: shown
                anchors.verticalCenter: parent.verticalCenter
                text: pass.text === "" ? "PASSWORD" : "•".repeat(pass.text.length)
                color: pass.text === "" ? "#2e2e2b" : root.ink
                font.family: root.display
                font.weight: Font.Black
                font.variableAxes: { "wdth": 70, "wght": 900 }
                font.pixelSize: 104 * root.s
            }
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 14 * root.s
                height: 84 * root.s
                color: root.acc
                transform: Translate { x: -12 * root.s }
            }
        }
    }

    // the hint: under the field, or under the block while a key is plugged in
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.height / 2 + (root.inField || root.fieldP > 0 ? 28 * root.s : 60 * root.s)
        opacity: root.done ? 0 : Math.max(root.fieldP, root.keyAsks && !root.checking ? 1 : 0)
        Behavior on opacity { NumberAnimation { duration: 200 } }
        text: root.wrong ? "WRONG PASSWORD"
            : root.keyAsks ? (root.inField ? "TOUCH THE KEY · OR TYPE YOUR PASSWORD" : "TOUCH THE KEY")
            : "TYPE YOUR PASSWORD"
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
        onTextChanged: {
            if (text !== "") {
                root.wrong = false;
                root.wake();
            }
        }
        // a plain Enter wakes the field too (typing wakes it through onTextChanged)
        Keys.onReturnPressed: { root.wake(); root.submit(); }
        Keys.onEnterPressed: { root.wake(); root.submit(); }
        Keys.onEscapePressed: text = ""
    }
}
