// Control center MEDIA tab (v2 mock: clockmost-desktop design/v2-2026-10-25/cc.html?tab=media): the cover as three
// staggered slices (the ground's hero motif), the title as the poster, the spectrum doubling as the seek bar (played
// part orange), transport as one ruled row with play/pause as the orange slab, volume, players, OPEN PHONOGRAPH.
// One orange, no album colour. Player: Media; spectrum: phonograph-audio (cava relay, ws://127.0.0.1:47862, 48 bars
// 0..255 per frame), connected only while this tab is open.
import QtQuick
import QtWebSockets
import Quickshell
import Quickshell.Services.Mpris

CCTab {
    id: root

    readonly property var player: Media.player
    property var bars: new Array(48).fill(0)
    readonly property real progress: player && player.length > 0 ? Math.min(1, player.position / player.length) : 0
    readonly property bool spotify: (player?.identity ?? "").toLowerCase() === "spotify"

    codePrefix: "" // the mock: no CLOCKMOST · here, the button needs the room
    code: "PH-01 · " + (player?.volumeSupported ? Math.round(player.volume * 100) + "%" : "IDLE")

    actions: Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: openLabel.implicitWidth + 28
        height: 32
        color: openArea.containsMouse ? GroundTheme.acc : Theme.ink
        visible: root.player !== null || root.spotify
        Text {
            id: openLabel
            anchors.centerIn: parent
            text: (root.spotify || !root.player ? "OPEN PHONOGRAPH" : "OPEN " + (root.player.identity || "PLAYER").toUpperCase()) + "  →"
            color: GroundTheme.bg
            font.family: Theme.mono
            font.weight: Font.Bold
            font.pixelSize: 11
            font.letterSpacing: 2.2
        }
        MouseArea {
            id: openArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (root.player?.canRaise)
                    root.player.raise();
                else
                    Apps.run(["spotify-launcher"], "spotify");
                ControlCenter.close();
            }
        }
    }

    // position only updates when asked; tick it while playing (smooth enough for the seek bar)
    Timer {
        interval: 250
        repeat: true
        running: Media.playing
        onTriggered: root.player.positionChanged()
    }

    WebSocket {
        id: spectrum
        url: "ws://127.0.0.1:47862"
        active: ControlCenter.open
        onBinaryMessageReceived: message => root.bars = Array.from(new Uint8Array(message))
        onStatusChanged: if (spectrum.status === WebSocket.Closed || spectrum.status === WebSocket.Error) root.bars = new Array(48).fill(0)
    }
    // the relay restarts / starts late: retry
    Timer {
        interval: 2000
        repeat: true
        running: ControlCenter.open && spectrum.status !== WebSocket.Open && spectrum.status !== WebSocket.Connecting
        onTriggered: {
            spectrum.active = false;
            spectrum.active = Qt.binding(() => ControlCenter.open);
        }
    }

    // ---- lead: cover slices + title poster ----
    Item {
        id: lead
        x: 22
        width: parent.width - 44
        height: 18 + 190 + 16

        // three windows onto one cover, staggered; no cover = the orange fade
        Repeater {
            model: [[0, 168], [14, 176], [4, 150]]
            Item {
                id: slice
                required property var modelData
                required property int index
                x: index * 58
                y: 18 + modelData[0]
                width: 52
                height: modelData[1]
                clip: true
                Rectangle {
                    x: -slice.x
                    y: -slice.modelData[0]
                    width: 168
                    height: 190
                    visible: cover.status !== Image.Ready
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0; color: GroundTheme.acc }
                        GradientStop { position: 0.5; color: "#6b2a14" }
                        GradientStop { position: 0.85; color: "#1f1d1b" }
                    }
                }
                Image {
                    id: cover
                    x: -slice.x
                    y: -slice.modelData[0]
                    width: 168
                    height: 190
                    source: root.player?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(380, 380)
                    asynchronous: true
                }
                Rectangle { width: 2; height: parent.height; color: Theme.ink }
            }
        }

        Column {
            x: 168 + 18
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            width: parent.width - x
            spacing: 0
            Text {
                width: parent.width
                elide: Text.ElideRight
                bottomPadding: 10
                readonly property var n: root.player?.metadata?.["xesam:trackNumber"]
                text: (root.player ? "NOW PLAYING · " + (root.player.identity || "PLAYER").toUpperCase() : "MPRIS · IDLE")
                    + (n ? " · TRACK " + String(n).padStart(2, "0") : "")
                color: Theme.dim
                font.family: Theme.mono
                font.pixelSize: 11
                font.letterSpacing: 2
            }
            Text {
                width: parent.width
                height: Math.min(implicitHeight, 150)
                text: (root.player?.trackTitle || "NOTHING PLAYING").toUpperCase()
                color: root.player ? Theme.ink : Theme.dim
                font.family: GroundTheme.display
                font.weight: Font.Black
                font.variableAxes: { "wdth": 68, "wght": 900 }
                font.pixelSize: 84
                fontSizeMode: Text.Fit
                minimumPixelSize: 30
                wrapMode: Text.Wrap
                maximumLineCount: 2
                lineHeightMode: Text.ProportionalHeight
                lineHeight: 0.84
                verticalAlignment: Text.AlignBottom
            }
            Text {
                width: parent.width
                elide: Text.ElideRight
                topPadding: 10
                visible: text !== ""
                text: (root.player?.trackArtist || "").toUpperCase()
                color: Theme.ink
                font.family: GroundTheme.display
                font.weight: Font.ExtraBold
                font.variableAxes: { "wdth": 75, "wght": 800 }
                font.pixelSize: 22
            }
            Text {
                width: parent.width
                elide: Text.ElideRight
                topPadding: 6
                visible: text !== ""
                text: (root.player?.trackAlbum || "").toUpperCase()
                color: Theme.dim
                font.family: Theme.mono
                font.pixelSize: 11
                font.letterSpacing: 2
            }
        }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 2; color: Theme.ink }
    }

    // ---- spectrum = seek bar: bars up to the playhead orange, click / drag to seek ----
    Item { width: 1; height: 14 }
    Item {
        x: 22
        width: parent.width - 44
        height: 52
        Row {
            anchors.bottom: parent.bottom
            width: parent.width
            spacing: 3
            Repeater {
                model: 48
                Rectangle {
                    required property int index
                    readonly property bool played: (index + 0.5) / 48 <= root.progress
                    anchors.bottom: parent.bottom
                    width: (parent.width - 47 * 3) / 48
                    height: 3 + (root.bars[index] ?? 0) / 255 * 49
                    color: played ? GroundTheme.acc : GroundTheme.over(Qt.rgba(Theme.dim.r, Theme.dim.g, Theme.dim.b, 0.55))
                }
            }
        }
        MouseArea {
            anchors.fill: parent
            enabled: root.player?.canSeek ?? false
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            function seek(x) {
                root.player.position = Math.max(0, Math.min(1, x / width)) * root.player.length;
            }
            onPressed: mouse => seek(mouse.x)
            onPositionChanged: mouse => { if (pressed) seek(mouse.x); }
        }
    }
    Item {
        x: 22
        width: parent.width - 44
        height: 30
        Text {
            y: 6
            text: Media.clock(root.player?.position)
            color: Theme.dim
            font.family: Theme.mono
            font.pixelSize: 10
            font.letterSpacing: 1.6
        }
        Text {
            y: 6
            anchors.right: parent.right
            text: Media.clock(root.player?.length)
            color: Theme.dim
            font.family: Theme.mono
            font.pixelSize: 10
            font.letterSpacing: 1.6
        }
    }

    // ---- transport: one ruled row, play/pause the wide orange slab ----
    Item {
        x: 22
        width: parent.width - 44
        height: 48
        Rectangle { width: parent.width; height: 1; color: GroundTheme.lineSolid }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: GroundTheme.lineSolid }
        Row {
            id: transport
            y: 1
            readonly property real unit: width / 6
            width: parent.width
            height: parent.height - 2
            Cell {
                label: "SHUF"
                on: root.player?.shuffle ?? false
                enabled: root.player?.shuffleSupported ?? false
                onClicked: root.player.shuffle = !root.player.shuffle
            }
            Cell {
                glyph: "M18 6v12L8 12zM6 6v12"
                enabled: root.player?.canGoPrevious ?? false
                onClicked: root.player.previous()
            }
            Rectangle {
                width: transport.unit * 2
                height: parent.height
                color: root.player?.canTogglePlaying ?? false ? GroundTheme.acc : GroundTheme.over(Qt.rgba(GroundTheme.acc.r, GroundTheme.acc.g, GroundTheme.acc.b, 0.4))
                Row {
                    anchors.centerIn: parent
                    spacing: 10
                    Glyph {
                        anchors.verticalCenter: parent.verticalCenter
                        size: 16
                        path: Media.playing ? "M8 5v14M16 5v14" : "M8 5v14l11-7z"
                        color: GroundTheme.accInk
                        stroke: Media.playing ? 3 : 2
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Media.playing ? "PAUSE" : "PLAY"
                        color: GroundTheme.accInk
                        font.family: Theme.mono
                        font.weight: Font.Bold
                        font.pixelSize: 11
                        font.letterSpacing: 2
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    enabled: root.player?.canTogglePlaying ?? false
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.player.togglePlaying()
                }
            }
            Cell {
                glyph: "M6 6v12l10-6zM18 6v12"
                enabled: root.player?.canGoNext ?? false
                onClicked: root.player.next()
            }
            Cell {
                // Spotify's cycle: off -> all -> one -> off
                label: root.player?.loopState === MprisLoopState.Track ? "RPT 1" : "RPT"
                divider: false
                on: (root.player?.loopState ?? MprisLoopState.None) !== MprisLoopState.None
                enabled: root.player?.loopSupported ?? false
                onClicked: root.player.loopState = root.player.loopState === MprisLoopState.None ? MprisLoopState.Playlist
                    : root.player.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None
            }
        }
    }

    // ---- volume + players ----
    Item { width: 1; height: 12 }
    CCLevel {
        x: 22
        width: parent.width - 44
        compact: true
        visible: root.player?.volumeSupported ?? false
        label: "VOLUME"
        value: root.player?.volume ?? 0
        onChanged: v => root.player.volume = v
    }
    Item {
        x: 22
        width: parent.width - 44
        height: 34
        visible: Media.players.length > 0
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "PLAYERS"
            color: Theme.ink
            font.family: Theme.mono
            font.pixelSize: 11
            font.letterSpacing: 2
        }
        Text {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 120
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideLeft
            text: Media.players.map(p => (p.identity || "?").toUpperCase()).join(" · ")
            color: Theme.dim
            font.family: Theme.mono
            font.pixelSize: 11
            font.letterSpacing: 2
        }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: GroundTheme.lineSolid }
    }
    Item { width: 1; height: 16 }

    component Cell: Item {
        id: cell
        property string label: ""
        property string glyph: ""
        property bool on: false
        property bool divider: true
        signal clicked

        width: transport.unit
        height: parent.height
        Rectangle { anchors.fill: parent; color: area.containsMouse ? GroundTheme.over(Qt.rgba(1, 1, 1, 0.05)) : GroundTheme.bg }
        Text {
            visible: cell.label !== ""
            anchors.centerIn: parent
            text: cell.label
            color: !cell.enabled ? Theme.faint : cell.on ? GroundTheme.acc : Theme.ink
            font.family: Theme.mono
            font.pixelSize: 11
            font.letterSpacing: 2
        }
        Glyph {
            visible: cell.glyph !== ""
            anchors.centerIn: parent
            size: 16
            path: cell.glyph
            color: !cell.enabled ? Theme.faint : area.containsMouse ? GroundTheme.acc : Theme.ink
        }
        Rectangle { visible: cell.divider; anchors.right: parent.right; width: 1; height: parent.height; color: GroundTheme.lineSolid }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: cell.clicked()
        }
    }
}
