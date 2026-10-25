// Small shared pieces for the HA sections: header with BACK, label/value rows, toggles, big numbers.
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    function fmtTime(iso) {
        if (!iso || iso === "unknown" || iso === "unavailable") return "--";
        const d = new Date(iso);
        return isNaN(d) ? String(iso).toUpperCase() : Qt.formatDateTime(d, "ddd hh:mm").toUpperCase();
    }
}
