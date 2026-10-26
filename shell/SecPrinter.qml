// ENDER / ELEGOO: one printer - state, file, progress (and the plate's cover image when there is one), the readings,
// then the dashboard's controls: button groups (danger ones arm first) and number targets (nozzle / bed).
import QtQuick

Column {
    id: root

    property string title
    property string stateId
    property string progressId
    property string coverId: "" // image.* entity
    property var rows: [] // [label, entity, unit]
    property var groups: [] // [[label, button entity, danger], ...] per group
    property var targets: [] // [label, number entity, unit]

    readonly property real progress: Number(HaClient.st(progressId)) || 0
    readonly property string cover: coverId !== "" ? (HaClient.attr(coverId, "entity_picture") ?? "") : ""

    spacing: 18

    SecHead { title: root.title; meta: HaClient.st(root.stateId).toUpperCase(); onBack: HaSections.current = "" }

    Item {
        width: 560
        height: Math.max(pct.height, coverBox.visible ? coverBox.height : 0)
        Text {
            id: pct
            text: Math.round(root.progress) + "%"
            color: HaClient.st(root.stateId) === "printing" ? GroundTheme.acc : GroundTheme.ink
            font.family: GroundTheme.display
            font.pixelSize: 96
            font.weight: Font.Black
            font.variableAxes: { "wdth": 70, "wght": 900 }
        }
        // the plate's cover image (Elegoo), framed
        Rectangle {
            id: coverBox
            visible: cover.status === Image.Ready
            anchors.right: parent.right
            width: 150
            height: 110
            color: "transparent"
            border.width: 1.5
            border.color: GroundTheme.line
            Image {
                id: cover
                anchors.fill: parent
                anchors.margins: 6
                source: root.cover !== "" ? HaClient.base + root.cover : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }
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
                // timestamps (done at / ends) read as "SUN 23:45"; update entities as words
                value: modelData[1].startsWith("update.") ? (raw === "on" ? "UPDATE AVAILABLE" : raw === "off" ? "UP TO DATE" : "--")
                    : (/^\d{4}-\d\d-\d\dT/.test(raw) ? SecKit.fmtTime(raw) : (raw || "--")) + (modelData[2] ?? "")
                strong: raw === "on" && modelData[1].startsWith("update.")
            }
        }
    }
    Column {
        visible: root.targets.length > 0
        width: 560
        Repeater {
            model: root.targets
            SecNumber {
                required property var modelData
                width: 560
                label: modelData[0]
                entity: modelData[1]
                unit: modelData[2] ?? ""
            }
        }
    }
    Repeater {
        model: root.groups
        Flow {
            required property var modelData
            width: 560
            spacing: 6
            Repeater {
                model: parent.modelData
                SecButton {
                    required property var modelData
                    label: modelData[0]
                    danger: modelData[2] ?? false
                    onFired: HaClient.call("button", "press", modelData[1])
                }
            }
        }
    }
}
