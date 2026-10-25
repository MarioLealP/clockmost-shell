// MISC: Spotify (HA's media player) + the shopping list (todo items fetched on open; click = done).
import QtQuick

Column {
    id: root

    readonly property string sp: "media_player.spotify_clockmost"
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

    Column {
        width: 560
        spacing: 6
        Text { text: "SPOTIFY  ·  " + HaClient.st(root.sp).toUpperCase(); color: GroundTheme.ink2; font.family: GroundTheme.mono; font.pixelSize: 11; font.letterSpacing: 2 }
        Text { width: 560; elide: Text.ElideRight; text: (HaClient.attr(root.sp, "media_title") ?? "—").toUpperCase(); color: GroundTheme.ink; font.family: GroundTheme.display; font.pixelSize: 40; font.weight: Font.Black; font.variableAxes: { "wdth": 70 } }
        Text { text: (HaClient.attr(root.sp, "media_artist") ?? "").toUpperCase(); color: GroundTheme.ink; font.family: GroundTheme.mono; font.pixelSize: 13; font.letterSpacing: 2 }
        Item { width: 1; height: 8 }
        Row {
            spacing: 6
            Btn { label: "◀◀"; onHit: HaClient.call("media_player", "media_previous_track", root.sp) }
            Btn { label: HaClient.st(root.sp) === "playing" ? "PAUSE" : "PLAY"; onHit: HaClient.call("media_player", "media_play_pause", root.sp) }
            Btn { label: "▶▶"; onHit: HaClient.call("media_player", "media_next_track", root.sp) }
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
