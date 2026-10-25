// Control center HOME (v2): ONLINE / OFFLINE as the lead, the quick switches as rows, output + mic levels, now
// playing. Same data as before (Networking, Bluetooth, Vpn, Notifs, NightLight, Pipewire, Mpris) - new look.
import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

Item {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var wired: Networking.devices.values.find(d => d.type === DeviceType.Wired) ?? null
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var btDevice: adapter ? adapter.devices.values.find(d => d.connected) ?? null : null
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null

    function clock(seconds) {
        const s = Math.max(0, Math.floor(seconds || 0));
        const mm = String(Math.floor(s % 3600 / 60)).padStart(2, "0") + ":" + String(s % 60).padStart(2, "0");
        return s >= 3600 ? Math.floor(s / 3600) + ":" + mm : mm;
    }

    width: 540
    implicitHeight: col.height + 52

    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    Column {
        id: col
        x: 22
        y: 18
        width: parent.width - 44
        spacing: 0

        CCHero {
            size: 96
            value: root.wired?.connected ? "ONLINE" : "OFFLINE"
            sub: !root.wired ? "NO WIRED DEVICE"
                : "ETHERNET  ·  " + (root.wired.name || "").toUpperCase()
                  + (root.wired.linkSpeed >= 1000 ? "  ·  " + root.wired.linkSpeed / 1000 + " GBIT" : root.wired.linkSpeed > 0 ? "  ·  " + root.wired.linkSpeed + " MBIT" : "")
        }

        CCSwitch {
            label: "BLUETOOTH"
            available: root.adapter !== null
            on: root.adapter?.enabled ?? false
            state: !root.adapter ? "NO ADAPTER" : root.btDevice ? root.btDevice.name.toUpperCase() : ""
            onClicked: root.adapter.enabled = !root.adapter.enabled
        }
        CCSwitch {
            label: "VPN"
            available: Vpn.name !== ""
            on: Vpn.active
            state: Vpn.name === "" ? "NOT SET UP" : Vpn.active ? Vpn.name.toUpperCase() : ""
            onClicked: Vpn.toggle()
        }
        CCSwitch {
            label: "DO NOT DISTURB"
            on: Notifs.dnd
            state: Notifs.dnd ? "CRITICAL ONLY" : ""
            onClicked: Notifs.dnd = !Notifs.dnd
        }
        CCSwitch {
            label: "NIGHT LIGHT"
            on: NightLight.enabled
            state: !NightLight.enabled ? "" : NightLight.running ? "ACTIVE" : "WAITING"
            onClicked: NightLight.toggle()
        }
        CCSwitch {
            label: "GAME MODE"
            available: false
            state: "SOON"
        }

        Item { width: 1; height: 16 }
        Row {
            width: parent.width
            spacing: 22
            CCLevel {
                width: (parent.width - 22) / 2
                label: "OUTPUT"
                value: Math.min(1, root.sink?.audio?.volume ?? 0)
                muted: root.sink?.audio?.muted ?? false
                onChanged: v => { if (root.sink?.audio) root.sink.audio.volume = v; }
                onLabelClicked: if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted
            }
            CCLevel {
                width: (parent.width - 22) / 2
                label: "MIC"
                value: Math.min(1, root.source?.audio?.volume ?? 0)
                muted: root.source?.audio?.muted ?? false
                onChanged: v => { if (root.source?.audio) root.source.audio.volume = v; }
                onLabelClicked: if (root.source?.audio) root.source.audio.muted = !root.source.audio.muted
            }
        }

        Item { width: 1; height: 18 }
        Rectangle { width: parent.width; height: 1; color: GroundTheme.line }
        Item { width: 1; height: 12 }
        Column {
            visible: root.player !== null
            width: parent.width
            spacing: 4
            // MPRIS position isn't pushed; tick it while showing
            Timer {
                running: root.player?.isPlaying ?? false
                interval: 1000
                repeat: true
                onTriggered: root.player.positionChanged()
            }
            Text { text: "NOW PLAYING  ·  " + (root.player?.identity ?? "").toUpperCase(); color: Theme.dim; font.family: Theme.mono; font.pixelSize: 10; font.letterSpacing: 2 }
            Text {
                width: parent.width
                elide: Text.ElideRight
                text: (root.player?.trackTitle ?? "").toUpperCase()
                color: Theme.ink
                font.family: GroundTheme.display
                font.weight: Font.Black
                font.variableAxes: { "wdth": 70 }
                font.pixelSize: 40
            }
            Item {
                width: parent.width
                height: 24
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - ctl.width - 10
                    elide: Text.ElideRight
                    text: (root.player?.trackArtist ?? "").toUpperCase() + "  ·  " + root.clock(root.player?.position) + " / " + root.clock(root.player?.length)
                    color: Theme.dim
                    font.family: Theme.mono
                    font.pixelSize: 11
                    font.letterSpacing: 2
                }
                Row {
                    id: ctl
                    anchors.right: parent.right
                    spacing: 4
                    Repeater {
                        model: [{ t: "◀◀", f: () => root.player.previous() }, { t: root.player?.isPlaying ? "PAUSE" : "PLAY", f: () => root.player.togglePlaying() }, { t: "▶▶", f: () => root.player.next() }]
                        Rectangle {
                            required property var modelData
                            width: bt.implicitWidth + 16
                            height: 24
                            color: ba.containsMouse ? Theme.ink : "transparent"
                            border.width: 1
                            border.color: GroundTheme.line
                            Text { id: bt; anchors.centerIn: parent; text: parent.modelData.t; color: ba.containsMouse ? GroundTheme.bg : Theme.ink; font.family: Theme.mono; font.pixelSize: 10 }
                            MouseArea { id: ba; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.modelData.f() }
                        }
                    }
                }
            }
        }
        Text { visible: root.player === null; text: "NOTHING PLAYING"; color: Theme.dim; font.family: Theme.mono; font.pixelSize: 11; font.letterSpacing: 2 }
    }
}
