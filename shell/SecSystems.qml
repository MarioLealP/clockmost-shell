// SYSTEMS: Felt's status sensors per area + Home Assistant's own backup.
import QtQuick

Column {
    spacing: 18

    SecHead { title: "SYSTEMS"; meta: HaSections.systems(); onBack: HaSections.current = "" }

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
    }
}
