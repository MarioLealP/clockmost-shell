// The clockmost login (desktop-environment-v2 stage 4). One user, no choices: a loading screen while the tang server
// on the home LAN comes up, then a no-password login that the tang gate (pam_exec, /usr/lib/clockmost-shell/tang-gate)
// checks for real. No tang within the cutoff, or the gate says no: the loading turns into the password field. Either
// way a login that goes through moves on to phase 2 (the desktop loading).
// Functional pass: the loading pieces are placeholders until the motion pass.
import QtQuick

Rectangle {
    id: root

    readonly property color bg: "#1a1a18"
    readonly property color ink: "#e8e6df"
    readonly property color ink2: "#8a8881"
    readonly property color acc: "#ff5f1f"
    readonly property string mono: "JetBrains Mono"
    readonly property string display: archivo.status === FontLoader.Ready ? archivo.name : "sans-serif"
    FontLoader {
        id: archivo
        source: "file:///usr/share/clockmost-shell/assets/fonts/Archivo-Variable.ttf"
    }

    // wait = phase 1 (looking for tang), field = the password, go = phase 2 (logging in)
    property string mode: "wait"
    property bool wrong: false
    readonly property string user: userModel.lastUser || userModel.data(userModel.index(0, 0), Qt.UserRole + 1)
    readonly property int session: sessionModel.lastIndex
    readonly property string tangUrl: config.tangUrl || ""

    function login(pw) {
        mode = "go";
        sddm.login(user, pw, session);
    }
    function fallBack() {
        mode = "field";
        pass.forceActiveFocus();
    }

    color: bg

    Connections {
        target: sddm
        function onLoginFailed() {
            root.wrong = pass.text !== "";
            pass.text = "";
            root.mode = "field";
            pass.forceActiveFocus();
        }
    }

    // ask tang every half second; the first answer starts the no-password login
    Timer {
        interval: 500
        repeat: true
        triggeredOnStart: true
        running: root.mode === "wait" && root.tangUrl !== ""
        onTriggered: {
            const x = new XMLHttpRequest();
            x.onreadystatechange = () => {
                if (x.readyState === XMLHttpRequest.DONE && x.status === 200 && root.mode === "wait")
                    root.login("");
            };
            x.open("GET", root.tangUrl + "/adv");
            x.send();
        }
    }
    Timer {
        interval: (Number(config.cutoff) || 9) * 1000
        running: root.mode === "wait"
        onTriggered: root.fallBack()
    }
    Component.onCompleted: if (tangUrl === "") fallBack()

    // phase 1 / phase 2 placeholder: a turning orange frame
    Item {
        anchors.centerIn: parent
        width: 96
        height: 96
        visible: root.mode !== "field"
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.width: 3
            border.color: root.acc
            RotationAnimation on rotation {
                from: 0
                to: 360
                duration: root.mode === "go" ? 600 : 1500
                loops: Animation.Infinite
            }
        }
        Text {
            anchors.top: parent.bottom
            anchors.topMargin: 48
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.mode === "go" ? "ENTERING" : "LOOKING FOR HOME"
            color: root.ink2
            font.family: root.mono
            font.pixelSize: 12
            font.letterSpacing: 3
        }
    }

    // the fallback: the password as the poster, like the drawer's search
    Column {
        anchors.centerIn: parent
        spacing: 24
        visible: root.mode === "field"
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
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
                text: pass.text === "" ? "PASSWORD" : "•".repeat(pass.text.length)
                color: pass.text === "" ? "#2e2e2b" : root.ink
                font.family: root.display
                font.weight: Font.Black
                font.variableAxes: { "wdth": 70, "wght": 900 }
                font.pixelSize: 104
            }
            Rectangle {
                anchors.verticalCenter: shown.verticalCenter
                width: 14
                height: 84
                color: root.acc
                transform: Translate { x: -12 }
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.wrong ? "WRONG PASSWORD" : "HOME NOT FOUND · TYPE YOUR PASSWORD"
            color: root.wrong ? root.acc : root.ink2
            font.family: root.mono
            font.pixelSize: 12
            font.letterSpacing: 3
        }
    }
    TextInput {
        id: pass
        width: 1
        height: 1
        opacity: 0
        echoMode: TextInput.Password
        onTextChanged: if (text !== "") root.wrong = false
        Keys.onReturnPressed: if (text !== "") root.login(text)
        Keys.onEnterPressed: if (text !== "") root.login(text)
    }
}
