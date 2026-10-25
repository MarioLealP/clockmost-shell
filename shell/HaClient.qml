// Home Assistant over its WebSocket API, as the "clockmost-desktop" user (non-admin, local-only). The token comes
// from KeePassXC's Secret Service at runtime and only lives in this process. subscribe_entities with an explicit
// entity list keeps the traffic to what the ground shows.
pragma Singleton
import QtQuick
import QtWebSockets
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string url: "ws://192.168.10.117:8123/api/websocket"
    property var entities: [] // set by HaSections
    property var states: ({}) // entity_id -> { s: state, a: attributes }
    property bool connected: false

    // the token survives hot reloads in memory (PersistentProperties), so a reload doesn't re-read the Secret Service
    // (KeePassXC shows a notification per read)
    property alias token: kept.token
    PersistentProperties {
        id: kept
        reloadableId: "haclient-token"
        property string token: ""
    }
    property int nextId: 1

    function st(id) { return root.states[id]?.s ?? ""; }
    function attr(id, key) { return root.states[id]?.a?.[key]; }
    function isOn(id) { return root.st(id) === "on"; }

    property var pending: ({}) // id -> callback, for request/response commands (todo items)

    function call(domain, service, entityId, data) {
        root.send({ type: "call_service", domain: domain, service: service, target: { entity_id: entityId }, service_data: data ?? {} });
    }
    function request(msg, cb) {
        root.pending[root.nextId] = cb;
        root.send(msg);
    }

    function toggle(entityId) {
        root.send({ type: "call_service", domain: entityId.split(".")[0], service: "toggle", target: { entity_id: entityId } });
    }

    function send(msg) {
        msg.id = root.nextId++;
        sock.sendTextMessage(JSON.stringify(msg));
    }

    function handle(m) {
        if (m.type === "auth_required") {
            sock.sendTextMessage(JSON.stringify({ type: "auth", access_token: root.token }));
        } else if (m.type === "auth_ok") {
            root.connected = true;
            if (root.entities.length)
                root.send({ type: "subscribe_entities", entity_ids: root.entities });
        } else if (m.type === "auth_invalid") {
            console.warn("ha: auth_invalid - check the clockmost-desktop token in KeePassXC");
        } else if (m.type === "result" && root.pending[m.id]) {
            const cb = root.pending[m.id];
            delete root.pending[m.id];
            cb(m.success ? m.result : null);
        } else if (m.type === "event" && m.event) {
            root.apply(m.event);
        }
    }

    // compressed state stream: a = added (full), c = changed (+ merged / - removed attrs), r = removed
    function apply(ev) {
        const next = Object.assign({}, root.states);
        for (const id in ev.a ?? {})
            next[id] = { s: ev.a[id].s, a: ev.a[id].a ?? {} };
        for (const id in ev.c ?? {}) {
            const cur = next[id] ?? { s: "", a: {} };
            const plus = ev.c[id]["+"] ?? {}, minus = ev.c[id]["-"] ?? {};
            const a = Object.assign({}, cur.a, plus.a ?? {});
            for (const k of minus.a ?? [])
                delete a[k];
            next[id] = { s: plus.s ?? cur.s, a: a };
        }
        for (const id of ev.r ?? [])
            delete next[id];
        root.states = next;
    }

    onEntitiesChanged: if (root.connected) root.send({ type: "subscribe_entities", entity_ids: root.entities })

    Component.onCompleted: if (root.token.length > 0) sock.active = true
    Process {
        command: ["secret-tool", "lookup", "service", "clockmost-ha", "account", "clockmost-desktop"]
        running: root.token.length === 0
        stdout: StdioCollector {
            onStreamFinished: {
                root.token = text.trim();
                sock.active = root.token.length > 0;
                if (!sock.active)
                    console.warn("ha: no token in the Secret Service (KeePassXC locked?)");
            }
        }
    }

    WebSocket {
        id: sock
        url: root.url
        active: false
        onTextMessageReceived: message => root.handle(JSON.parse(message))
        onStatusChanged: {
            if (sock.status === WebSocket.Closed || sock.status === WebSocket.Error) {
                root.connected = false;
                retry.restart();
            }
        }
    }

    // HA restarts / Wi-Fi blips: reconnect every 10 s
    Timer {
        id: retry
        interval: 10000
        onTriggered: {
            sock.active = false;
            sock.active = root.token.length > 0;
        }
    }
}
