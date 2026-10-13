// The notification server (org.freedesktop.Notifications). Claimed at startup, so Plasma's on-demand stub never
// starts. Keeps the history (with arrival time + read state), the popup queue and do-not-disturb.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property var records: [] // newest first: [{n, time, read}]
    property var popups: [] // records currently shown as popups
    property bool dnd: false
    readonly property int unread: records.filter(r => !r.read).length
    readonly property var groups: {
        const map = {};
        for (const r of records) {
            const app = r.n.appName || "Unknown";
            if (!map[app])
                map[app] = [];
            map[app].push(r);
        }
        return Object.keys(map).map(k => ({ app: k, items: map[k] }));
    }

    function ago(t) {
        const m = Math.floor((Date.now() - t) / 60000);
        return m < 1 ? "NOW" : m < 60 ? m + "M" : m < 1440 ? Math.floor(m / 60) + "H" : Math.floor(m / 1440) + "D";
    }

    function hidePopup(rec) {
        popups = popups.filter(p => p !== rec);
    }
    function markAllRead() {
        if (unread === 0)
            return;
        records = records.map(r => Object.assign({}, r, { read: true }));
        // keep popup entries pointing at the same objects as records
        popups = popups.map(p => records.find(r => r.n === p.n)).filter(p => p);
    }
    function dismiss(rec) {
        rec.n.dismiss(); // the closed signal removes it from records/popups
    }
    function clearGroup(app) {
        for (const r of records.filter(r => (r.n.appName || "Unknown") === app))
            r.n.dismiss();
    }
    function clearAll() {
        for (const r of records.slice())
            r.n.dismiss();
    }

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true;
            const rec = { n: n, time: Date.now(), read: false };
            n.closed.connect(() => {
                root.records = root.records.filter(r => r.n !== n);
                root.popups = root.popups.filter(r => r.n !== n);
            });
            root.records = [rec].concat(root.records);
            // DND swallows popups, except critical ones
            if (!root.dnd || n.urgency === NotificationUrgency.Critical)
                root.popups = [rec].concat(root.popups).slice(0, 4);
        }
    }
}
