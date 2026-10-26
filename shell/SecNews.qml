// NEWS: the stories behind each news sensor (attributes.stories), newest first per feed.
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
                required property var modelData
                width: 560
                spacing: 4
                Text { text: modelData.replace("sensor.news_", "").replace("_", " ").toUpperCase(); color: GroundTheme.acc; font.family: GroundTheme.mono; font.pixelSize: 11; font.letterSpacing: 2 }
                Repeater {
                    model: (HaClient.attr(modelData, "stories") ?? []).slice(0, 3)
                    Text {
                        required property var modelData
                        width: 560
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        text: modelData.title ?? ""
                        color: GroundTheme.ink
                        font.family: GroundTheme.display
                        font.pixelSize: 17
                        font.weight: Font.DemiBold
                        font.variableAxes: { "wght": 600 }
                    }
                }
            }
        }
    }
}
