// Control center MEDIA tab = the media mock (ds-topbar-v2 ?state=media, "built from the phonograph"): the cover on a
// slab of its own colour, title / ARTIST / album, the visualizer strip with the timer tag on its seam, a seek bar,
// transport (shuffle, prev, play, next, repeat), OPEN PHONOGRAPH. Dropped from the mock (Mario 2026-10-14): lyrics and
// up next (both live only inside the Spotify page). Player + accent: Media; spectrum: phonograph-audio (cava relay,
// ws://127.0.0.1:47862, 48 bars 0..255 per frame), connected only while this tab is open.
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes
import QtWebSockets
import Quickshell
import Quickshell.Services.Mpris

CCTab {
    id: root

    readonly property var player: Media.player
    property color acc: Media.accent
    Behavior on acc { ColorAnimation { duration: 1200; easing.type: Easing.InOutQuad } }
    property var bars: new Array(48).fill(0)
    readonly property real progress: player && player.length > 0 ? Math.min(1, player.position / player.length) : 0
    readonly property bool spotify: (player?.identity ?? "").toLowerCase() === "spotify"

    function tint(a) {
        return Qt.rgba(acc.r, acc.g, acc.b, a);
    }
    // the cover's "catalogue number": stable per album
    function catalogue(s) {
        let h = 0;
        for (const c of s || "")
            h = (h * 31 + c.charCodeAt(0)) % 9000;
        return "SR-" + (1000 + h);
    }

    codePrefix: "" // the mock: no CLOCKMOST · here, the button needs the room
    code: "PH-01 · " + (player?.volumeSupported ? Math.round(player.volume * 100) + "%" : "IDLE")

    actions: Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: openLabel.implicitWidth + 28
        height: 30
        color: openArea.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.2)
        visible: root.player !== null || root.spotify
        Text {
            id: openLabel
            anchors.centerIn: parent
            text: root.spotify || !root.player ? "OPEN PHONOGRAPH" : "OPEN " + (root.player.identity || "PLAYER").toUpperCase()
            color: Theme.ink2
            font.family: Theme.mono
            font.weight: Font.Bold
            font.pixelSize: 10
            font.letterSpacing: Theme.em(10, 0.2)
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
                    Quickshell.execDetached(["spotify-launcher"]);
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

    // ---- feature: the slab (album colour, fading right) with the art floating on it ----
    Item {
        id: feat
        width: parent.width
        height: 18 + Math.max(150, info.implicitHeight) + 16

        Rectangle {
            x: 10
            y: 10
            width: parent.width - 50
            height: parent.height - 16
            opacity: 0.8
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: root.tint(0.55) }
                GradientStop { position: 0.55; color: root.tint(0.18) }
                GradientStop { position: 1; color: root.tint(0) }
            }
        }

        // art: 150px, corners cut 16px top-right + bottom-left, drop shadow down-right
        Item {
            id: art
            x: 22
            y: 18
            width: 150
            height: 150
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.45)
                shadowHorizontalOffset: 8
                shadowVerticalOffset: 10
                shadowBlur: 0.4
            }

            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeWidth: 0
                    fillGradient: LinearGradient {
                        x1: 0; y1: 0; x2: 150; y2: 150
                        GradientStop { position: 0; color: root.acc }
                        GradientStop { position: 1; color: root.tint(0.75) }
                    }
                    PathSvg { path: "M0 0H134L150 16V150H16L0 134z" }
                }
            }
            Image {
                anchors.fill: parent
                source: root.player?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(300, 300)
                visible: status === Image.Ready
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: artMask
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1
                }
            }
            Shape {
                id: artMask
                anchors.fill: parent
                visible: false
                layer.enabled: true
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeWidth: 0
                    fillColor: "black"
                    PathSvg { path: "M0 0H134L150 16V150H16L0 134z" }
                }
            }
            // the mock's print marks: dot patch, barcode, catalogue line (dark ink, read on the colour slab
            // when there is no cover)
            Canvas {
                x: parent.width - 60
                y: 14
                width: 50
                height: 40
                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    ctx.fillStyle = Qt.rgba(17 / 255, 17 / 255, 17 / 255, 0.3);
                    for (let y = 3; y < height; y += 6)
                        for (let x = 3; x < width; x += 6)
                            ctx.fillRect(x - 0.5, y - 0.5, 1.2, 1.2);
                }
            }
            Barcode {
                x: 12
                y: parent.height - 22 - 9
                width: 56
                height: 9
                color: Qt.rgba(17 / 255, 17 / 255, 17 / 255, 0.75)
            }
            Text {
                x: 12
                y: parent.height - 9 - height
                text: root.catalogue(root.player?.trackAlbum || root.player?.trackTitle) + " · 33 RPM · SIDE A"
                color: Qt.rgba(17 / 255, 17 / 255, 17 / 255, 0.7)
                font.family: Theme.mono
                font.pixelSize: 7
                font.letterSpacing: Theme.em(7, 0.14)
            }
        }

        Column {
            id: info
            x: art.x + art.width + 18
            y: 18
            width: parent.width - x - 18

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: "PHONOGRAPH · " + (root.player ? (root.player.identity || "PLAYER").toUpperCase() : "MPRIS")
                color: Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.55)
                font.family: Theme.mono
                font.pixelSize: 8
                font.letterSpacing: Theme.em(8, 0.2)
            }
            Item { width: 1; height: 8 }
            Text {
                width: parent.width
                text: root.player?.trackTitle || "Nothing playing"
                color: root.player ? Theme.ink : Theme.dim
                font.family: Theme.body
                font.weight: Font.DemiBold
                font.pixelSize: 24
                lineHeight: 1.1
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
            }
            Item { width: 1; height: 6 }
            Text {
                width: parent.width
                elide: Text.ElideRight
                text: root.player ? (root.player.trackArtist || "").toUpperCase() : "MPRIS · IDLE"
                color: Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.75)
                font.family: Theme.mono
                font.pixelSize: 10
                font.letterSpacing: Theme.em(10, 0.24)
            }
            Item { width: 1; height: 12 }
            Rectangle { width: parent.width; height: 1; color: Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.25) }
            Item { width: 1; height: 10 }
            // the lyric lines' place: album (the "on" line, yellow tick) + track number
            Item {
                width: parent.width
                height: albumText.implicitHeight
                visible: !!root.player?.trackAlbum
                Rectangle { y: 2; width: 3; height: parent.height - 4; color: Theme.yellow }
                Text {
                    id: albumText
                    x: 10
                    width: parent.width - 10
                    elide: Text.ElideRight
                    text: root.player?.trackAlbum ?? ""
                    color: Theme.ink
                    font.family: Theme.body
                    font.weight: Font.DemiBold
                    font.pixelSize: 13
                }
            }
            Text {
                readonly property var n: root.player?.metadata?.["xesam:trackNumber"]
                x: 10
                topPadding: 4
                visible: !!n
                text: "TRACK " + String(n).padStart(2, "0")
                color: Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.5)
                font.family: Theme.mono
                font.pixelSize: 10
                font.letterSpacing: Theme.em(10, 0.2)
            }
        }
    }

    // ---- visualizer strip + black timer tag on the seam ----
    Item {
        x: 22
        width: parent.width - 44
        height: 34

        Row {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 1
            width: parent.width
            spacing: 3
            Repeater {
                model: 48
                Rectangle {
                    required property int index
                    anchors.bottom: parent.bottom
                    width: (parent.width - 47 * 3) / 48
                    height: 2 + (root.bars[index] ?? 0) / 255 * 30
                    color: root.tint(0.55)
                }
            }
        }
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: Qt.rgba(1, 1, 1, 0.14)
        }
        Rectangle {
            y: parent.height + 10 - height
            width: tag.implicitWidth + 16
            height: 20
            color: "#0b0b0c"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.14)
            Row {
                id: tag
                anchors.centerIn: parent
                spacing: 6
                // pause bars while playing, a play triangle while paused
                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 8
                    height: 10
                    Rectangle { visible: Media.playing; width: 3; height: 10; color: Theme.ink }
                    Rectangle { visible: Media.playing; x: 5; width: 3; height: 10; color: Theme.ink }
                    Shape {
                        visible: !Media.playing
                        ShapePath {
                            strokeWidth: 0
                            fillColor: Theme.ink
                            PathSvg { path: "M0 0L8 5L0 10z" }
                        }
                    }
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Media.clock(root.player?.position) + " / " + Media.clock(root.player?.length)
                    color: Theme.ink
                    font.family: Theme.mono
                    font.weight: Font.Bold
                    font.pixelSize: 10
                    font.letterSpacing: Theme.em(10, 0.1)
                }
            }
        }
    }

    // ---- seek bar: 3px, album colour, ink knob; click / drag to seek ----
    Item { width: 1; height: 18 }
    Item {
        x: 22
        width: parent.width - 44
        height: 3
        Rectangle { anchors.fill: parent; color: root.tint(0.2) }
        Rectangle {
            width: parent.width * root.progress
            height: 3
            color: root.acc
            Rectangle { x: parent.width - 2; y: -4; width: 3; height: 11; color: Theme.ink }
        }
        MouseArea {
            anchors.fill: parent
            anchors.topMargin: -8
            anchors.bottomMargin: -8
            enabled: root.player?.canSeek ?? false
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            function seek(x) {
                root.player.position = Math.max(0, Math.min(1, x / width)) * root.player.length;
            }
            onPressed: mouse => seek(mouse.x)
            onPositionChanged: mouse => { if (pressed) seek(mouse.x); }
        }
    }

    // ---- transport: shuffle, prev, play/pause (ink square), next, repeat; on = album colour ----
    Item { width: 1; height: 14 }
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 18
        TransportButton {
            path: "M3 7h4l10 10h4M3 17h4l3-3M14 10l3-3h4M18 4l3 3-3 3M18 14l3 3-3 3"
            on: root.player?.shuffle ?? false
            enabled: root.player?.shuffleSupported ?? false
            onClicked: root.player.shuffle = !root.player.shuffle
        }
        TransportButton {
            path: "M18 6v12L8 12zM6 6v12"
            enabled: root.player?.canGoPrevious ?? false
            onClicked: root.player.previous()
        }
        Rectangle {
            width: 40
            height: 40
            color: Theme.ink
            opacity: root.player?.canTogglePlaying ? 1 : 0.4
            Glyph {
                anchors.centerIn: parent
                path: Media.playing ? "M8 5v14M16 5v14" : "M8 5v14l11-7z"
                color: Theme.plateInk
                stroke: Media.playing ? 3 : 2
            }
            MouseArea {
                anchors.fill: parent
                enabled: root.player?.canTogglePlaying ?? false
                cursorShape: Qt.PointingHandCursor
                onClicked: root.player.togglePlaying()
            }
        }
        TransportButton {
            path: "M6 6v12l10-6zM18 6v12"
            enabled: root.player?.canGoNext ?? false
            onClicked: root.player.next()
        }
        TransportButton {
            path: "M4 9V7h14l-3-3M20 15v2H6l3 3"
            on: (root.player?.loopState ?? MprisLoopState.None) !== MprisLoopState.None
            one: root.player?.loopState === MprisLoopState.Track
            enabled: root.player?.loopSupported ?? false
            // Spotify's cycle: off -> all -> one -> off
            onClicked: root.player.loopState = root.player.loopState === MprisLoopState.None ? MprisLoopState.Playlist
                : root.player.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None
        }
    }
    Item { width: 1; height: 12 }

    component TransportButton: Item {
        id: btn
        property string path: ""
        property bool on: false
        property bool one: false
        signal clicked

        anchors.verticalCenter: parent.verticalCenter
        width: 22
        height: 40
        opacity: enabled ? 1 : 0.35
        Glyph {
            anchors.centerIn: parent
            path: btn.path
            color: btn.on ? root.acc : hover.containsMouse ? Theme.ink : Theme.ink2
        }
        Text {
            visible: btn.one
            x: parent.width - 4
            y: 8
            text: "1"
            color: root.acc
            font.family: Theme.mono
            font.weight: Font.Bold
            font.pixelSize: 8
        }
        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }
}
