// clockmost KWin bridge script - runs inside KWin, loaded by kwin-bridge.
// On every relevant change it sends one JSON snapshot to the bridge over D-Bus:
//   {current, desktops: [{id, name, number}], windows: [{id, app, title, desktops, onAll, active, minimized, attention}]}
// The bridge prints it as one line; the Quickshell bar reads those lines.

function windowInfo(w) {
    return {
        id: w.internalId.toString(),
        app: w.resourceClass,
        title: w.caption,
        desktops: w.desktops.map(d => d.id),
        onAll: w.onAllDesktops,
        active: w === workspace.activeWindow,
        minimized: w.minimized,
        attention: w.demandsAttention,
    };
}

function snapshot() {
    const windows = workspace.windowList().filter(w => w.normalWindow && !w.skipTaskbar);
    const data = {
        current: workspace.currentDesktop.id,
        desktops: workspace.desktops.map(d => ({ id: d.id, name: d.name, number: d.x11DesktopNumber })),
        windows: windows.map(windowInfo),
    };
    callDBus("org.clockmost.KWinBridge", "/Bridge", "org.clockmost.KWinBridge", "Update", JSON.stringify(data));
}

function watch(w) {
    w.captionChanged.connect(snapshot);
    w.desktopsChanged.connect(snapshot);
    w.minimizedChanged.connect(snapshot);
    w.demandsAttentionChanged.connect(snapshot);
}

workspace.windowList().forEach(watch);
workspace.windowAdded.connect(w => { watch(w); snapshot(); });
workspace.windowRemoved.connect(snapshot);
workspace.windowActivated.connect(snapshot);
workspace.currentDesktopChanged.connect(snapshot);
workspace.desktopsChanged.connect(snapshot);
snapshot();
