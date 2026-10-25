// MISC: now playing (local media players) + the shopping list (todo items fetched on open; click = done).
import QtQuick

Column {
    id: root

    property var items: []

    function load() {
        HaClient.request({ type: "todo/item/list", entity_id: "todo.shopping_list" }, r => root.items = (r?.items ?? []).filter(i => i.status === "needs_action"));
    }

    spacing: 18
    Component.onCompleted: load()
    Connections {
        target: HaClient
        function onStatesChanged() { if (String(root.items.length) !== HaClient.st("todo.shopping_list")) root.load(); }
    }

    component Btn: Rectangle {
        property string label
        signal hit()
        width: bt.implicitWidth + 24
        height: 36
        color: ma.containsMouse ? GroundTheme.ink : "transparent"
        border.width: 1.5
        border.color: GroundTheme.ink
        Text { id: bt; anchors.centerIn: parent; text: parent.label; color: ma.containsMouse ? GroundTheme.bg : GroundTheme.ink; font.family: GroundTheme.mono; font.pixelSize: 12 }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: parent.hit() }
    }

    SecHead { title: "MISC"; meta: HaSections.misc(); onBack: HaSections.current = "" }

    // now playing from the desktop's own media players (MPRIS: Spotify, YouTube in Firefox, ...) - Mario 2026-10-25:
    // HA's Spotify entity carries no track info; "swap to local media, so it also picks up ytb"
    Row {
        width: 560
        spacing: 20
        Image {
            width: 150
            height: 150
            visible: Media.player !== null
            source: Media.player?.trackArtUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            Rectangle { anchors.fill: parent; anchors.margins: -6; color: "transparent"; border.width: 2; border.color: GroundTheme.ink }
        }
        Column {
            width: 560 - 170
            spacing: 6
            Text { text: Media.player ? (Media.player.identity + "  ·  " + (Media.playing ? "PLAYING" : "PAUSED")).toUpperCase() : "NOTHING PLAYING"; color: GroundTheme.ink2; font.family: GroundTheme.mono; font.pixelSize: 11; font.letterSpacing: 2 }
            Text { width: parent.width; wrapMode: Text.WordWrap; maximumLineCount: 2; elide: Text.ElideRight; text: (Media.player?.trackTitle ?? "").toUpperCase(); color: GroundTheme.ink; font.family: GroundTheme.display; font.pixelSize: 36; font.weight: Font.Black; font.variableAxes: { "wdth": 70 }; lineHeight: 0.9 }
            Text { text: (Media.player?.trackArtist ?? "").toUpperCase(); color: GroundTheme.ink; font.family: GroundTheme.mono; font.pixelSize: 13; font.letterSpacing: 2 }
            Text { text: (Media.player?.trackAlbum ?? "").toUpperCase(); color: GroundTheme.ink2; font.family: GroundTheme.mono; font.pixelSize: 11; font.letterSpacing: 2; width: parent.width; elide: Text.ElideRight }
            Item { width: 1; height: 6 }
            Row {
                visible: Media.player !== null
                spacing: 6
                Btn { label: "◀◀"; onHit: Media.player.previous() }
                Btn { label: Media.playing ? "PAUSE" : "PLAY"; onHit: Media.player.togglePlaying() }
                Btn { label: "▶▶"; onHit: Media.player.next() }
            }
        }
    }

    Column {
        width: 560
        Text { bottomPadding: 8; text: "SHOPPING LIST"; color: GroundTheme.ink2; font.family: GroundTheme.mono; font.pixelSize: 11; font.letterSpacing: 2 }
        Repeater {
            model: root.items
            Item {
                required property var modelData
                width: 560
                height: 34
                Text { anchors.verticalCenter: parent.verticalCenter; text: "○  " + modelData.summary; color: GroundTheme.ink; font.family: GroundTheme.mono; font.pixelSize: 13 }
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: GroundTheme.line }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: HaClient.call("todo", "update_item", "todo.shopping_list", { item: modelData.uid, status: "completed" })
                }
            }
        }
        Text { visible: root.items.length === 0; text: "NOTHING TO BUY"; color: GroundTheme.ink2; font.family: GroundTheme.mono; font.pixelSize: 12 }
    }
}
