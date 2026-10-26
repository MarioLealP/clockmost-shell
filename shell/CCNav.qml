// The control center's navigation (v2): the HA list's pattern - numbered words, the active one orange; who you are
// + LOCK / SLEEP / OFF at the bottom.
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property real minHeight: 0
    readonly property string user: (Quickshell.env("USER") || "user").toUpperCase()

    width: 200
    implicitHeight: Math.max(list.height + who.height + 48, minHeight)

    Column {
        id: list
        x: 16
        y: 16
        width: parent.width - 32
        Repeater {
            model: ControlCenter.tabs
            Rectangle {
                id: cell
                required property var modelData
                required property int index
                readonly property bool active: ControlCenter.tab === modelData.id
                width: list.width
                height: 37
                color: active ? GroundTheme.acc : area.containsMouse ? Qt.rgba(1, 1, 1, 0.05) : "transparent"
                Text {
                    x: cell.active ? 10 : 4
                    anchors.verticalCenter: parent.verticalCenter
                    text: String(cell.index + 1).padStart(2, "0")
                    color: cell.active ? GroundTheme.accInk : Theme.dim
                    font.family: Theme.mono
                    font.pixelSize: 10
                }
                Text {
                    x: (cell.active ? 10 : 4) + 26
                    anchors.verticalCenter: parent.verticalCenter
                    text: cell.modelData.label
                    color: cell.active ? GroundTheme.accInk : Theme.ink
                    font.family: GroundTheme.display
                    font.weight: Font.ExtraBold
                    font.variableAxes: { "wdth": 75, "wght": 800 }
                    font.pixelSize: 19
                }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: GroundTheme.line; visible: !cell.active }
                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ControlCenter.tab = cell.modelData.id
                }
            }
        }
    }

    Column {
        id: who
        x: 20
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 18
        spacing: 3
        Text {
            text: root.user
            color: Theme.ink
            font.family: GroundTheme.display
            font.weight: Font.Black
            font.variableAxes: { "wdth": 70, "wght": 900 }
            font.pixelSize: 22
        }
        Text {
            text: "CLOCKMOST-DESKTOP"
            color: Theme.dim
            font.family: Theme.mono
            font.pixelSize: 9
            font.letterSpacing: 2
        }
        Item { width: 1; height: 8 }
        Row {
            spacing: 5
            Repeater {
                model: [
                    { label: "LOCK", cmd: ["loginctl", "lock-session"], hot: false },
                    { label: "SLEEP", cmd: ["systemctl", "suspend"], hot: false },
                    { label: "OFF", cmd: ["qdbus6", "org.kde.LogoutPrompt", "/LogoutPrompt", "promptAll"], hot: true }
                ]
                Rectangle {
                    id: act
                    required property var modelData
                    width: at.implicitWidth + 14
                    height: 24
                    color: aa.containsMouse ? (act.modelData.hot ? GroundTheme.acc : Qt.rgba(1, 1, 1, 0.08)) : "transparent"
                    border.width: 1
                    border.color: act.modelData.hot ? GroundTheme.acc : GroundTheme.line
                    Text {
                        id: at
                        anchors.centerIn: parent
                        text: act.modelData.label
                        color: act.modelData.hot ? (aa.containsMouse ? GroundTheme.accInk : GroundTheme.acc) : Theme.ink
                        font.family: Theme.mono
                        font.pixelSize: 10
                        font.letterSpacing: 2
                    }
                    MouseArea {
                        id: aa
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ControlCenter.close();
                            Quickshell.execDetached(act.modelData.cmd);
                        }
                    }
                }
            }
        }
    }
}
