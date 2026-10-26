// SYSTEMS: what needs Mario (Felt's count as the big number + the latest items), Felt's status per area, Home
// Assistant's own backup, the plugs' energy, and the tools (Zabbix / Wazuh / ntfy open in the browser).
import QtQuick

Column {
    id: root

    spacing: 18

    readonly property int needs: Number(HaClient.st("sensor.felt_needs_you")) || 0
    readonly property var latest: HaClient.attr("sensor.felt_needs_you", "latest") ?? []

    SecHead { title: "SYSTEMS"; meta: HaSections.systems(); onBack: HaSections.current = "" }

    Row {
        spacing: 14
        Text {
            text: String(root.needs).padStart(2, "0")
            color: root.needs > 0 ? GroundTheme.acc : GroundTheme.ink
            font.family: GroundTheme.display
            font.pixelSize: 96
            font.weight: Font.Black
            font.variableAxes: { "wdth": 62, "wght": 900 }
        }
        Text {
            anchors.bottom: parent.bottom
            bottomPadding: 14
            text: "NEEDS YOU\nFELT  ·  OPEN ITEMS"
            color: GroundTheme.ink2
            font.family: GroundTheme.mono
            font.pixelSize: 10
            font.letterSpacing: 2
            lineHeight: 1.4
        }
    }

    Column {
        width: 560
        visible: root.latest.length > 0
        Text { bottomPadding: 8; text: "LATEST"; color: GroundTheme.ink2; font.family: GroundTheme.mono; font.pixelSize: 11; font.letterSpacing: 2 }
        Repeater {
            model: root.latest
            SecRow {
                required property var modelData
                width: 560
                label: String(modelData.area ?? "").toUpperCase()
                value: modelData.title + (modelData.last_at ? "  ·  " + Qt.formatDateTime(new Date(modelData.last_at + "Z"), "dd MMM hh:mm").toUpperCase() : "")
            }
        }
    }

    Column {
        width: 560
        Repeater {
            model: [["SERVER", "sensor.felt_server"], ["BACKUPS", "sensor.felt_backups"], ["SECURITY", "sensor.felt_security"],
                ["DESKTOP", "sensor.felt_desktop"], ["LAPTOP", "sensor.felt_laptop"], ["ROUTER", "sensor.felt_router"],
                ["HA BACKUP", "sensor.backup_state"]]
            SecRow {
                required property var modelData
                width: 560
                label: modelData[0]
                value: HaClient.st(modelData[1]).toUpperCase()
                strong: ["needs-you", "failed"].includes(HaClient.st(modelData[1]))
            }
        }
        SecRow { width: 560; label: "LAST HA BACKUP"; value: SecKit.fmtTime(HaClient.st("sensor.backup_last_successful_automatic_backup")) }
        SecRow { width: 560; label: "SHELF ENERGY"; value: (HaClient.st("sensor.shelf_energy") || "--") + " kWh" }
        SecRow { width: 560; label: "EXTRA PLUG ENERGY"; value: (HaClient.st("sensor.extraplug_energy") || "--") + " kWh" }
    }

    Row {
        spacing: 6
        Repeater {
            model: [["ZABBIX", "https://zabbix.clockmost.com"], ["WAZUH", "https://wazuh.clockmost.com"], ["NTFY", "https://ntfy.clockmost.com"]]
            SecButton {
                required property var modelData
                label: modelData[0] + "  ↗"
                onFired: Apps.run(["xdg-open", modelData[1]], "xdg-open")
            }
        }
    }
}
