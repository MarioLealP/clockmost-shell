// .felt: Felt's dedicated button - magenta glyph block + name + status line. Felt herself is felt-tray (shell-
// neutral); this chip only talks to its session-bus API org.clockmost.Felt: Status (polled) and ShowChat (click).
import QtQuick
import QtQuick.Shapes
import Quickshell.Io

Rectangle {
    id: root

    // "online" / "offline" / "checking" from felt-tray; "" = felt-tray not running
    property string feltState: ""
    readonly property string status: feltState === "online" ? "ONLINE" : feltState === "offline" ? "OFFLINE" : feltState === "checking" ? "WAKING" : "ASLEEP"
    readonly property color statusColor: feltState === "online" ? Theme.green : feltState === "offline" ? Theme.crimson : Theme.dim

    readonly property var api: ["busctl", "--user", "--", "org.clockmost.Felt", "/org/clockmost/Felt", "org.clockmost.Felt"]

    implicitWidth: row.implicitWidth + 12
    implicitHeight: 38
    color: Qt.rgba(12 / 255, 13 / 255, 15 / 255, 0.7)
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.10)

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Rectangle {
            width: 38
            height: 38
            color: Theme.magenta

            // the mock's Felt glyph (24-unit viewBox) at 22px, stroke 2.2, square caps
            Shape {
                anchors.centerIn: parent
                width: 24
                height: 24
                scale: 22 / 24
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: Theme.plateInk
                    strokeWidth: 2.2
                    fillColor: "transparent"
                    capStyle: ShapePath.SquareCap
                    PathSvg { path: "M5 20v-2a7 7 0 0 1 14 0v2 M8 8a4 4 0 1 0 8 0a4 4 0 1 0 -8 0 M9 3l1.5 2 M15 3l-1.5 2" }
                }
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3
            Text {
                text: "FELT"
                color: Theme.ink
                font.family: Theme.mono
                font.weight: Font.Bold
                font.pixelSize: 11
                font.letterSpacing: Theme.em(11, 0.26)
            }
            Text {
                text: "● " + root.status
                color: root.statusColor
                font.family: Theme.mono
                font.pixelSize: 8
                font.letterSpacing: Theme.em(8, 0.18)
            }
        }
    }

    Process {
        id: reader
        command: ["busctl", "--user", "get-property", "org.clockmost.Felt", "/org/clockmost/Felt", "org.clockmost.Felt", "Status"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.trim().match(/^s "(.*)"$/);
                root.feltState = m ? m[1] : "";
            }
        }
        onExited: code => {
            if (code !== 0)
                root.feltState = "";
        }
    }
    Process {
        id: opener
        command: ["busctl", "--user", "call", "org.clockmost.Felt", "/org/clockmost/Felt", "org.clockmost.Felt", "ShowChat"]
    }
    Timer {
        interval: 15000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: reader.running = true
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: if (root.feltState !== "") opener.running = true
    }
}
