// TODAY: the agenda (every calendar, next 14 days, calendar.get_events with return_response, refreshed every 10 min),
// the phone's next alarm + battery. No weather: the date stack by the clock has it (Mario 2026-10-26).
import QtQuick

Column {
    id: root

    spacing: 18

    property var agenda: [] // {start: Date, allDay, summary, cal}

    function refresh() {
        HaClient.request({ type: "call_service", domain: "calendar", service: "get_events", target: { entity_id: HaSections.calendars },
            service_data: { duration: { days: 14 } }, return_response: true },
            r => {
                const out = [];
                for (const [cal, v] of Object.entries(r?.response ?? {}))
                    for (const e of v.events ?? [])
                        out.push({ start: new Date(e.start.length === 10 ? e.start + "T00:00:00" : e.start), allDay: e.start.length === 10, summary: e.summary, cal: cal });
                root.agenda = out.sort((a, b) => a.start - b.start).slice(0, 9);
            });
    }
    Component.onCompleted: refresh()
    Timer { interval: 600000; repeat: true; running: true; onTriggered: root.refresh() }

    SecHead { title: "TODAY"; meta: HaSections.today(); onBack: HaSections.current = "" }

    Column {
        width: 560
        Text { bottomPadding: 8; text: "AGENDA  ·  14 DAYS"; color: GroundTheme.ink2; font.family: GroundTheme.mono; font.pixelSize: 11; font.letterSpacing: 2 }
        Repeater {
            model: root.agenda
            SecRow {
                required property var modelData
                width: 560
                label: Qt.formatDate(modelData.start, "ddd dd").toUpperCase() + "  ·  " + (modelData.allDay ? "ALL DAY" : Qt.formatTime(modelData.start, "hh:mm"))
                value: modelData.summary
                strong: modelData.cal === "calendar.feriados_em_portugal" || modelData.cal === "calendar.aniversarios"
            }
        }
        SecRow { visible: root.agenda.length === 0; width: 560; label: "NOTHING"; value: "IN THE NEXT 14 DAYS" }
    }

    Column {
        width: 560
        SecRow { width: 560; label: "ALARM"; value: SecKit.fmtTime(HaClient.st("sensor.pocox7_next_alarm")); strong: true }
        SecRow { width: 560; label: "PHONE BATTERY"; value: (HaClient.st("sensor.pocox7_battery_level") || "--") + " %" }
    }
}
