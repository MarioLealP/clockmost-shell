// NEWS: the stories behind each news sensor (attributes.stories), newest first per feed, three at a time - ‹ › page
// through the rest (the dashboard's carousel), clicking a headline opens the article in the browser.
import QtQuick

Column {
    spacing: 18

    SecHead { title: "NEWS"; meta: HaSections.newsCount() + " STORIES"; onBack: HaSections.current = "" }

    Column {
        width: 560
        spacing: 14
        Repeater {
            model: HaSections.news.filter(id => (HaClient.attr(id, "stories") ?? []).length)
            Column {
                id: feed
                required property var modelData
                readonly property var stories: HaClient.attr(modelData, "stories") ?? []
                readonly property int pages: Math.ceil(stories.length / 3)
                property int page: 0
                width: 560
                spacing: 4
                Item {
                    width: 560
                    height: 20
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: feed.modelData.replace("sensor.news_", "").replace("_", " ").toUpperCase()
                        color: GroundTheme.acc
                        font.family: GroundTheme.mono
                        font.pixelSize: 11
                        font.letterSpacing: 2
                    }
                    Row {
                        visible: feed.pages > 1
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10
                        Text {
                            text: "‹"
                            color: paL.containsMouse ? GroundTheme.acc : GroundTheme.ink
                            font.family: GroundTheme.mono
                            font.pixelSize: 16
                            MouseArea { id: paL; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: feed.page = (feed.page + feed.pages - 1) % feed.pages }
                        }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: (feed.page + 1) + " / " + feed.pages; color: GroundTheme.ink2; font.family: GroundTheme.mono; font.pixelSize: 10; font.letterSpacing: 2 }
                        Text {
                            text: "›"
                            color: paR.containsMouse ? GroundTheme.acc : GroundTheme.ink
                            font.family: GroundTheme.mono
                            font.pixelSize: 16
                            MouseArea { id: paR; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: feed.page = (feed.page + 1) % feed.pages }
                        }
                    }
                }
                Repeater {
                    model: feed.stories.slice(feed.page * 3, feed.page * 3 + 3)
                    Text {
                        required property var modelData
                        width: 560
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        text: modelData.title ?? ""
                        color: hl.containsMouse && modelData.link ? GroundTheme.acc : GroundTheme.ink
                        font.family: GroundTheme.display
                        font.pixelSize: 17
                        font.weight: Font.DemiBold
                        font.variableAxes: { "wght": 600 }
                        MouseArea {
                            id: hl
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: !!parent.modelData.link
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Apps.run(["xdg-open", parent.modelData.link], "xdg-open")
                        }
                    }
                }
            }
        }
    }
}
