// Now playing as poster type (no cover - Mario 2026-10-25): label, huge title, artist, progress, time.
import QtQuick

Column {
    id: root

    readonly property var player: Media.player
    readonly property real len: player?.length ?? 0
    readonly property real pos: player?.position ?? 0

    function mmss(s) {
        const t = Math.max(0, Math.floor(s));
        return String(Math.floor(t / 60)).padStart(2, "0") + ":" + String(t % 60).padStart(2, "0");
    }

    visible: player !== null
    spacing: 4

    // MPRIS position isn't pushed; tick it while visible
    Timer {
        running: root.visible && (root.player?.isPlaying ?? false)
        interval: 1000
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    Text { text: "NOW PLAYING  ·  " + (root.player?.identity ?? "").toUpperCase(); color: GroundTheme.ink2; font.family: GroundTheme.mono; font.pixelSize: 11; font.letterSpacing: 3 }
    Text {
        text: (root.player?.trackTitle ?? "").toUpperCase()
        color: GroundTheme.ink
        font.family: GroundTheme.display
        // two lines max, kept clear of the dock (it starts ~530px to the right)
        width: 500
        font.pixelSize: 56
        font.weight: Font.Black
        font.variableAxes: { "wdth": 70, "wght": 900 }
        wrapMode: Text.WordWrap
        maximumLineCount: 2
        elide: Text.ElideRight
        lineHeight: 0.9
    }
    Text { bottomPadding: 8; text: (root.player?.trackArtist ?? "").toUpperCase(); color: GroundTheme.ink; font.family: GroundTheme.mono; font.pixelSize: 16; font.letterSpacing: 2 }
    Rectangle {
        width: 500
        height: 4
        color: GroundTheme.line
        Rectangle { width: root.len > 0 ? parent.width * Math.min(1, root.pos / root.len) : 0; height: parent.height; color: GroundTheme.acc }
    }
    Text { topPadding: 4; text: root.mmss(root.pos) + " / " + root.mmss(root.len); color: GroundTheme.ink2; font.family: GroundTheme.mono; font.pixelSize: 11; font.letterSpacing: 3 }
}
