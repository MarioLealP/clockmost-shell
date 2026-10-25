// ENDER / ELEGOO: one printer - state, file, progress, layers, times, temperatures.
import QtQuick

Column {
    id: root

    property string title
    property string stateId
    property string progressId
    property var rows: [] // [label, entity, unit]

    readonly property real progress: Number(HaClient.st(progressId)) || 0

    spacing: 18

    SecHead { title: root.title; meta: HaClient.st(root.stateId).toUpperCase(); onBack: HaSections.current = "" }

    Row {
        spacing: 16
        Text {
            text: Math.round(root.progress) + "%"
            color: HaClient.st(root.stateId) === "printing" ? GroundTheme.acc : GroundTheme.ink
            font.family: GroundTheme.display
            font.pixelSize: 96
            font.weight: Font.Black
            font.variableAxes: { "wdth": 70 }
        }
    }
    Rectangle {
        width: 560
        height: 6
        color: GroundTheme.line
        Rectangle { width: parent.width * Math.min(1, root.progress / 100); height: parent.height; color: GroundTheme.acc }
    }
    Column {
        width: 560
        Repeater {
            model: root.rows
            SecRow {
                required property var modelData
                width: 560
                label: modelData[0]
                readonly property string raw: HaClient.st(modelData[1])
                // timestamps (done at / ends) read as "SUN 23:45"
                value: (/^\d{4}-\d\d-\d\dT/.test(raw) ? SecKit.fmtTime(raw) : (raw || "--")) + (modelData[2] ?? "")
            }
        }
    }
}
