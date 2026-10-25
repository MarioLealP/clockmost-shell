// TODAY: weather now, the next event per calendar, the phone's next alarm.
import QtQuick

Column {
    id: root

    spacing: 18

    SecHead { title: "TODAY"; meta: HaSections.today(); onBack: HaSections.current = "" }

    Row {
        spacing: 18
        Text {
            text: Math.round(HaClient.attr("weather.forecast_home", "temperature") ?? 0) + "°"
            color: GroundTheme.ink
            font.family: GroundTheme.display
            font.pixelSize: 96
            font.weight: Font.Black
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            Text { text: HaClient.st("weather.forecast_home").toUpperCase(); color: GroundTheme.ink; font.family: GroundTheme.mono; font.pixelSize: 14; font.letterSpacing: 2 }
            Text { text: "HUMIDITY " + (HaClient.attr("weather.forecast_home", "humidity") ?? "--") + "%"; color: GroundTheme.ink2; font.family: GroundTheme.mono; font.pixelSize: 11; font.letterSpacing: 2 }
        }
    }

    Column {
        width: 560
        Text { bottomPadding: 8; text: "NEXT UP"; color: GroundTheme.ink2; font.family: GroundTheme.mono; font.pixelSize: 11; font.letterSpacing: 2 }
        Repeater {
            model: HaSections.calendars.filter(id => HaClient.attr(id, "message"))
                .sort((a, b) => String(HaClient.attr(a, "start_time")).localeCompare(String(HaClient.attr(b, "start_time"))))
            SecRow {
                required property var modelData
                width: 560
                label: SecKit.fmtTime(String(HaClient.attr(modelData, "start_time")).replace(" ", "T"))
                value: HaClient.attr(modelData, "message")
            }
        }
        SecRow { width: 560; label: "ALARM"; value: SecKit.fmtTime(HaClient.st("sensor.pocox7_next_alarm")); strong: true }
    }
}
