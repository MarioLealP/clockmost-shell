// The "Home" dashboard's sections (read 2026-10-25) and the one-line summary each shows in the ground's list.
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property string current: "" // the open section ("" = none); the ground pans while one is open

    readonly property var room: ["light.chandelure", "light.yeelight_colorb_0x1b2f7704", "light.yeelight_colorb_0x1b1932dc",
        "light.yeelight_colorb_0x1b19e91f", "light.yeelight_colorb_0x1be53fa1", "light.shelf", "switch.extraplug", "fan.core_300s_series"]
    readonly property var calendars: ["calendar.lealmario47_gmail_com", "calendar.lealmariop_gmail_com",
        "calendar.feriados_em_portugal", "calendar.aniversarios"]
    readonly property var news: ["sensor.news_portugal", "sensor.news_porto", "sensor.news_world", "sensor.news_tech",
        "sensor.news_games", "sensor.news_jn_kids"]

    readonly property var sections: [
        { name: "ROOM", summary: root.roomOn() + " ON" },
        { name: "MISC", summary: root.misc() }, { name: "TODAY", summary: root.today() },
        { name: "NEWS", summary: root.newsCount() + " STORIES" }, { name: "ENDER", summary: root.printer("sensor.ender_state", "sensor.ender_progress") },
        { name: "ELEGOO", summary: root.printer("sensor.3d_printer_status_atual", "sensor.elegoo_progress") },
        { name: "SYSTEMS", summary: root.systems() }
    ]

    function felt() {
        if (HaClient.isOn("switch.felt_dj_mode")) return "DJ";
        return HaClient.isOn("switch.felt_quiet") ? "QUIET" : "ON";
    }
    function roomOn() {
        return String(root.room.filter(id => HaClient.isOn(id)).length).padStart(2, "0");
    }
    function misc() {
        // now playing lives in MISC (Mario 2026-10-25), from HA's Spotify: the row shows the track while it plays
        const sp = "media_player.spotify_clockmost";
        if (HaClient.st(sp) === "playing" && HaClient.attr(sp, "media_title"))
            return "▶ " + String(HaClient.attr(sp, "media_title")).toUpperCase();
        const n = Number(HaClient.st("todo.shopping_list")) || 0;
        return n ? n + " TO BUY" : "";
    }
    function today() {
        // the soonest upcoming event across the calendars
        const starts = root.calendars.map(id => HaClient.attr(id, "start_time")).filter(s => s).map(s => new Date(s.replace(" ", "T"))).filter(d => d > new Date());
        if (!starts.length) return "";
        const d = starts.sort((x, y) => x - y)[0];
        return Qt.formatDateTime(d, "ddd hh:mm").toUpperCase();
    }
    function newsCount() {
        return root.news.reduce((n, id) => n + (Number(HaClient.st(id)) || 0), 0);
    }
    function printer(stateId, progressId) {
        const s = HaClient.st(stateId);
        if (!s) return "";
        return s === "printing" ? "PRINTING " + Math.round(Number(HaClient.st(progressId)) || 0) + "%" : s.toUpperCase();
    }
    function systems() {
        const n = Number(HaClient.st("sensor.felt_needs_you")) || 0;
        return n ? n + " NEED YOU" : "ALL OK";
    }

    Component.onCompleted: HaClient.entities = root.room.concat(root.calendars, root.news, [
        "switch.felt_quiet", "switch.felt_hidden", "switch.felt_dj_mode", "todo.shopping_list",
        "sensor.ender_state", "sensor.ender_progress", "sensor.3d_printer_status_atual", "sensor.elegoo_progress",
        "sensor.felt_needs_you", "sensor.shelf_power", "sensor.core_300s_series_pm2_5", "sensor.extraplug_power",
        "media_player.spotify_clockmost", "weather.forecast_home", "sensor.pocox7_next_alarm",
        "sensor.ender_file", "sensor.ender_layer", "sensor.ender_elapsed", "sensor.ender_time_left", "sensor.ender_done_at",
        "sensor.ender_nozzle", "sensor.ender_bed", "sensor.3d_printer_status_de_impressao", "sensor.elegoo_file",
        "sensor.3d_printer_current_layer", "sensor.3d_printer_total_layers", "sensor.3d_printer_remaining_print_time",
        "sensor.3d_printer_end_time", "sensor.3d_printer_uv_led_temp", "sensor.felt_server", "sensor.felt_backups",
        "sensor.felt_security", "sensor.felt_desktop", "sensor.felt_laptop", "sensor.felt_router", "sensor.backup_state",
        "sensor.backup_last_successful_automatic_backup"])
}
