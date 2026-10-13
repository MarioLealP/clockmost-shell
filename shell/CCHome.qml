// Control center HOME tab = the quick-settings mock (ds-topbar-v2 ?state=quick): user header, connection
// tiles, output/mic levels, now playing, settings / lock / power.
import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

Column {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var wired: Networking.devices.values.find(d => d.type === DeviceType.Wired) ?? null
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var btDevice: adapter ? adapter.devices.values.find(d => d.connected) ?? null : null
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null

    function run(cmd) {
        runner.command = cmd;
        runner.running = true;
    }
    function clock(seconds) {
        const s = Math.max(0, Math.floor(seconds || 0));
        const mm = String(Math.floor(s % 3600 / 60)).padStart(2, "0") + ":" + String(s % 60).padStart(2, "0");
        return s >= 3600 ? Math.floor(s / 3600) + ":" + mm : mm; // live streams run for hours
    }

    width: 432
    spacing: 0

    PwObjectTracker {
        objects: [root.sink, root.source]
    }
    Process {
        id: runner
    }

    // head: hatched strip with the user
    Item {
        width: parent.width
        height: 72
        Hatch {
            anchors.fill: parent
            color: Qt.rgba(1, 1, 1, 0.045)
        }
        Row {
            x: 18
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12
            Item {
                width: 42
                height: 42
                Shape {
                    anchors.fill: parent
                    ShapePath {
                        strokeWidth: 0
                        fillColor: Theme.ink
                        PathSvg { path: "M0 0H33L42 9V42H9L0 33z" }
                    }
                }
                Text {
                    anchors.centerIn: parent
                    text: SystemInfo.user.slice(0, 2).toUpperCase()
                    color: Theme.plateInk
                    font.family: Theme.mono
                    font.weight: Font.Bold
                    font.pixelSize: 13
                    font.letterSpacing: Theme.em(13, 0.1)
                }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                Text {
                    text: SystemInfo.user + "@" + SystemInfo.host
                    color: Theme.ink
                    font.family: Theme.body
                    font.weight: Font.DemiBold
                    font.pixelSize: 15
                }
                Micro {
                    text: "UP " + SystemInfo.uptime + " · KERNEL " + SystemInfo.kernel
                }
            }
        }
        // vertical micro + barcode, right
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Micro {
                anchors.verticalCenter: parent.verticalCenter
                text: "QS-01"
                rotation: -90
                width: implicitHeight
                horizontalAlignment: Text.AlignHCenter
            }
            Canvas {
                width: 8
                height: 34
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.fillStyle = Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.5);
                    for (let y = 0; y < height; y += 8) {
                        ctx.fillRect(0, y, width, 2);
                        ctx.fillRect(0, y + 4, width, 1);
                    }
                }
            }
        }
    }

    // rule: hairline + 8px minor / 48px major ticks
    Canvas {
        x: 18
        width: parent.width - 36
        height: 7
        onPaint: {
            const ctx = getContext("2d");
            ctx.fillStyle = Qt.rgba(1, 1, 1, 0.14);
            ctx.fillRect(0, 0, width, 1);
            ctx.fillStyle = Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.3);
            for (let x = 0; x < width; x += 8)
                ctx.fillRect(x, 0, 1, 3);
            ctx.fillStyle = Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.4);
            for (let x = 0; x < width; x += 48)
                ctx.fillRect(x, 0, 1, 6);
        }
    }

    Column {
        x: 18
        width: parent.width - 36
        topPadding: 14
        spacing: 10

        SectionLabel {
            text: "CONNECTIONS"
            note: "06"
        }
        Grid {
            width: parent.width
            columns: 2
            spacing: 8
            readonly property real cell: (width - spacing) / 2

            ToggleTile {
                width: parent.cell
                icon: Icons.ethernet
                title: "ETHERNET"
                index: "01"
                accent: Theme.cyan
                on: root.wired?.connected ?? false
                status: !root.wired ? "NO DEVICE" : root.wired.connected
                    ? "CONNECTED" + (root.wired.linkSpeed >= 1000 ? " · " + root.wired.linkSpeed / 1000 + "G" : root.wired.linkSpeed > 0 ? " · " + root.wired.linkSpeed + "M" : "")
                    : "DISCONNECTED"
                onClicked: ControlCenter.show("network")
            }
            ToggleTile {
                width: parent.cell
                icon: Icons.bluetooth
                title: "BLUETOOTH"
                index: "02"
                accent: "#5aa7ff"
                available: !!root.adapter
                on: root.adapter?.enabled ?? false
                status: !root.adapter ? "NO ADAPTER" : !root.adapter.enabled ? "OFF"
                    : root.btDevice ? (root.btDevice.name || root.btDevice.deviceName).toUpperCase() : "ON"
                onClicked: root.adapter.enabled = !root.adapter.enabled
            }
            ToggleTile {
                width: parent.cell
                icon: Icons.vpn
                title: "VPN"
                index: "03"
                accent: Theme.green
                available: Vpn.name !== ""
                on: Vpn.active
                status: Vpn.name === "" ? "NOT SET UP" : Vpn.active ? Vpn.name.toUpperCase() : "OFF"
                onClicked: Vpn.toggle()
            }
            ToggleTile {
                width: parent.cell
                icon: Icons.dnd
                title: "DO NOT DISTURB"
                index: "04"
                accent: Theme.orange
                on: Notifs.dnd
                status: Notifs.dnd ? "ON · CRITICAL ONLY" : "OFF"
                onClicked: Notifs.dnd = !Notifs.dnd
            }
            ToggleTile {
                width: parent.cell
                icon: Icons.nightLight
                title: "NIGHT LIGHT"
                index: "05"
                accent: "#cfc6f4"
                on: NightLight.enabled
                status: !NightLight.enabled ? "OFF" : NightLight.running ? "ON · ACTIVE" : "ON · WAITING"
                onClicked: NightLight.toggle()
            }
            ToggleTile {
                width: parent.cell
                icon: Icons.game
                title: "GAME MODE"
                index: "06"
                accent: Theme.magenta
                available: false
                status: "SOON"
            }
        }

        Item { width: 1; height: 6 }
        SectionLabel {
            text: "LEVELS"
        }
        LevelRow {
            width: parent.width
            icon: root.sink?.audio?.muted ? Icons.volumeMuted : Icons.volume
            accent: Theme.cyan
            name: "OUTPUT · " + ((root.sink?.description || root.sink?.nickname || "NO DEVICE").toUpperCase())
            value: Math.min(1, root.sink?.audio?.volume ?? 0)
            muted: root.sink?.audio?.muted ?? false
            onChanged: v => { if (root.sink?.audio) root.sink.audio.volume = v; }
            onIconClicked: if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted
        }
        LevelRow {
            width: parent.width
            icon: Icons.mic
            accent: Theme.green
            name: "MIC · " + ((root.source?.description || root.source?.nickname || "NO DEVICE").toUpperCase())
            value: Math.min(1, root.source?.audio?.volume ?? 0)
            muted: root.source?.audio?.muted ?? false
            onChanged: v => { if (root.source?.audio) root.source.audio.volume = v; }
            onIconClicked: if (root.source?.audio) root.source.audio.muted = !root.source.audio.muted
        }

        SectionLabel {
            text: "NOW PLAYING"
            note: root.player ? (root.player.identity || "").toUpperCase() : "IDLE"
        }
        // .qnp: lavender slab, chamfered art, title / ARTIST · elapsed / length, progress, transport
        Rectangle {
            width: parent.width
            height: 74
            border.width: 1
            border.color: Qt.rgba(207 / 255, 198 / 255, 244 / 255, 0.2)
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.rgba(207 / 255, 198 / 255, 244 / 255, 0.28) }
                GradientStop { position: 1; color: Qt.rgba(207 / 255, 198 / 255, 244 / 255, 0.05) }
            }
            Timer {
                interval: 1000
                repeat: true
                running: root.player?.isPlaying ?? false
                onTriggered: root.player.positionChanged()
            }
            Item {
                id: art
                x: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 54
                height: 54
                Shape {
                    anchors.fill: parent
                    ShapePath {
                        strokeWidth: 0
                        fillGradient: LinearGradient {
                            x1: 0; y1: 0; x2: 54; y2: 54
                            GradientStop { position: 0; color: "#e7e1fc" }
                            GradientStop { position: 1; color: "#b3a7e3" }
                        }
                        PathSvg { path: "M0 0H44L54 10V54H10L0 44z" }
                    }
                }
                Image {
                    anchors.fill: parent
                    source: root.player?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready
                }
            }
            Column {
                anchors.left: art.right
                anchors.leftMargin: 12
                anchors.right: controls.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.player?.trackTitle || "Nothing playing"
                    color: root.player ? Theme.ink : Theme.dim
                    font.family: Theme.body
                    font.weight: Font.DemiBold
                    font.pixelSize: 14
                }
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: root.player
                        ? (root.player.trackArtist || "").toUpperCase() + " · " + root.clock(root.player.position) + " / " + root.clock(root.player.length)
                        : "MPRIS · IDLE"
                    color: "#b9b2d6"
                    font.family: Theme.mono
                    font.pixelSize: 9
                    font.letterSpacing: Theme.em(9, 0.2)
                }
                Rectangle {
                    width: parent.width
                    height: 2
                    color: Qt.rgba(207 / 255, 198 / 255, 244 / 255, 0.2)
                    Rectangle {
                        height: parent.height
                        width: root.player && root.player.length > 0 ? parent.width * Math.min(1, root.player.position / root.player.length) : 0
                        color: "#cfc6f4"
                    }
                }
            }
            Row {
                id: controls
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                Item {
                    width: 30
                    height: 30
                    Glyph { anchors.centerIn: parent; path: Icons.prev; color: Theme.ink }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.player?.previous() }
                }
                Rectangle {
                    width: 30
                    height: 30
                    color: Theme.ink
                    Glyph {
                        anchors.centerIn: parent
                        size: 12
                        stroke: 3
                        color: Theme.plateInk
                        path: root.player?.isPlaying ? "M7 5v14M17 5v14" : "M7 4l12 8-12 8z"
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.player?.togglePlaying() }
                }
                Item {
                    width: 30
                    height: 30
                    Glyph { anchors.centerIn: parent; path: Icons.next; color: Theme.ink }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.player?.next() }
                }
            }
        }
        Item { width: 1; height: 4 }
    }

    // foot: barcode + micro, square actions (power in crimson), dotted edge
    Item {
        width: parent.width
        height: 62
        Rectangle { width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.08) }
        Row {
            x: 18
            y: 12
            height: 32
            spacing: 10
            Barcode {
                anchors.verticalCenter: parent.verticalCenter
                width: 90
                height: 10
                color: Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.45)
            }
            Micro {
                anchors.verticalCenter: parent.verticalCenter
                text: "CLOCKMOST · QS-01"
            }
        }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 18
            y: 12
            spacing: 6
            Repeater {
                model: [
                    { icon: Icons.settings, cmd: ["systemsettings"], power: false },
                    { icon: Icons.lock, cmd: ["loginctl", "lock-session"], power: false },
                    { icon: Icons.power, cmd: ["qdbus6", "org.kde.LogoutPrompt", "/LogoutPrompt", "promptAll"], power: true }
                ]
                Rectangle {
                    id: act
                    required property var modelData
                    width: 32
                    height: 32
                    color: actArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(1, 1, 1, 0.03)
                    border.width: 1
                    border.color: modelData.power ? Qt.rgba(217 / 255, 30 / 255, 54 / 255, 0.5) : Qt.rgba(1, 1, 1, 0.16)
                    Glyph {
                        anchors.centerIn: parent
                        size: 16
                        path: act.modelData.icon
                        color: act.modelData.power ? Theme.crimson : Theme.ink2
                    }
                    MouseArea {
                        id: actArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            ControlCenter.close();
                            root.run(act.modelData.cmd);
                        }
                    }
                }
            }
        }
        DotGrid {
            x: 18
            y: parent.height - 11
            width: parent.width - 36
            height: 6
            pitch: 8
            color: Qt.rgba(1, 1, 1, 0.16)
        }
    }
}
