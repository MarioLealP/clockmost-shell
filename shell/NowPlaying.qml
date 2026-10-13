// .np: now-playing slab - lavender gradient, notched art square, title + ARTIST · elapsed, 5-bar meter.
// Source: the first MPRIS player that is playing (else the first one). Nothing playing = muted slab.
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Services.Mpris

Rectangle {
    id: root

    readonly property var players: Mpris.players.values
    readonly property var player: players.find(p => p.isPlaying) ?? players[0] ?? null
    readonly property bool playing: player?.isPlaying ?? false

    function clock(seconds) {
        const s = Math.max(0, Math.floor(seconds || 0));
        return String(Math.floor(s / 60)).padStart(2, "0") + ":" + String(s % 60).padStart(2, "0");
    }

    implicitWidth: row.implicitWidth + 12
    implicitHeight: 34
    border.width: 1
    border.color: Qt.rgba(207 / 255, 198 / 255, 244 / 255, 0.22)
    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0; color: Qt.rgba(207 / 255, 198 / 255, 244 / 255, root.player ? 0.30 : 0.12) }
        GradientStop { position: 1; color: Qt.rgba(207 / 255, 198 / 255, 244 / 255, 0.06) }
    }

    // position only updates when asked; tick it while playing
    Timer {
        interval: 1000
        repeat: true
        running: root.playing
        onTriggered: root.player.positionChanged()
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: ControlCenter.toggle("media", QsWindow.window?.screen?.name ?? "")
    }

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        // art: 34x34, top-right corner cut 7px; album art when the player has one
        Item {
            width: 34
            height: 34
            Shape {
                anchors.fill: parent
                ShapePath {
                    strokeWidth: 0
                    fillGradient: LinearGradient {
                        x1: 0; y1: 0; x2: 34; y2: 34
                        GradientStop { position: 0; color: "#e4ddfb" }
                        GradientStop { position: 1; color: "#b9aee6" }
                    }
                    PathSvg { path: "M0 0H27L34 7V34H0z" }
                }
            }
            Image {
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
                layer.enabled: true
            }
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            width: Math.min(160, Math.max(titleText.implicitWidth, subText.implicitWidth))
            Text {
                id: titleText
                width: parent.width
                elide: Text.ElideRight
                text: root.player?.trackTitle || "Nothing playing"
                color: root.player ? Theme.ink : Theme.dim
                font.family: Theme.body
                font.weight: Font.DemiBold
                font.pixelSize: 11
            }
            Text {
                id: subText
                width: parent.width
                elide: Text.ElideRight
                text: root.player
                    ? ((root.player.trackArtist || root.player.identity || "").toUpperCase() + " · " + root.clock(root.player.position))
                    : "MPRIS · IDLE"
                color: "#b9b2d6"
                font.family: Theme.mono
                font.pixelSize: 8
                font.letterSpacing: Theme.em(8, 0.2)
            }
        }

        // level meter: 5 bars, dancing while playing (shape, not real levels - cava later)
        Row {
            anchors.verticalCenter: parent.verticalCenter
            height: 14
            spacing: 2
            Repeater {
                model: [6, 11, 8, 14, 5]
                Rectangle {
                    id: lvl
                    required property int modelData
                    anchors.bottom: parent.bottom
                    width: 2
                    height: modelData
                    color: Qt.rgba(207 / 255, 198 / 255, 244 / 255, 0.8)
                    opacity: root.player ? 1 : 0.35
                    Behavior on height { NumberAnimation { duration: 140; easing.type: Easing.OutQuad } }
                    Timer {
                        interval: 160 + lvl.modelData * 7
                        repeat: true
                        running: root.playing
                        onTriggered: lvl.height = 3 + Math.random() * 11
                        onRunningChanged: if (!running) lvl.height = lvl.modelData
                    }
                }
            }
        }
    }
}
