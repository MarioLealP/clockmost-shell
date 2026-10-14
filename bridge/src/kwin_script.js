// clockmost KWin bridge script - runs inside KWin, loaded by kwin-bridge.
// On every relevant change it sends one JSON snapshot to the bridge over D-Bus:
//   {current, desktops: [{id, name, number}],
//    windows: [{id, app, title, desktops, onAll, active, minimized, attention, output, x, y, w, h}]}
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
        output: w.output ? w.output.name : "",
        x: w.frameGeometry.x,
        y: w.frameGeometry.y,
        w: w.frameGeometry.width,
        h: w.frameGeometry.height,
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
    w.outputChanged.connect(snapshot);
    // geometry: skip the flood while dragging/resizing, send once when it ends
    w.frameGeometryChanged.connect(() => { if (!w.move && !w.resize) snapshot(); });
    w.interactiveMoveResizeFinished.connect(snapshot);
}

workspace.windowList().forEach(watch);
workspace.windowAdded.connect(w => { watch(w); snapshot(); });
workspace.windowRemoved.connect(snapshot);
workspace.windowActivated.connect(snapshot);
workspace.currentDesktopChanged.connect(snapshot);
workspace.desktopsChanged.connect(snapshot);
snapshot();

// a real-keyboard way to open the drawer (Ctrl+Alt+Space - Alt+Space stays KRunner's): Win is eaten by
// Windows/VMware in the test VM (Mario: "put it on some
// other key"). Same call as the Win tap. Rebind in System Settings > Shortcuts > KWin if it collides.
registerShortcut("clockmost-app-drawer", "clockmost: app drawer", "Ctrl+Alt+Space", () =>
    callDBus("org.clockmost.KWinBridge", "/Bridge", "org.clockmost.KWinBridge", "Reveal"));

// Win+V = clipboard history at the pointer, picking pastes (Windows; Mario 2026-10-14). Meta+V is Klipper's own
// popup by default - its kglobalshortcutsrc entry is set to none. Ctrl+Alt+V for the VM, where Win never arrives.
function clipboard() {
    const p = workspace.cursorPos;
    callDBus("org.clockmost.KWinBridge", "/Bridge", "org.clockmost.KWinBridge", "Update",
        JSON.stringify({ event: "clipboard", x: p.x, y: p.y }));
}
registerShortcut("clockmost-clipboard", "clockmost: clipboard history", "Meta+V", clipboard);
registerShortcut("clockmost-clipboard-alt", "clockmost: clipboard history (VM key)", "Ctrl+Alt+V", clipboard);

// commands from the shell (the dock): long-poll the bridge's Next, run what comes back, ask again
function findWindow(id) {
    return workspace.windowList().find(w => w.internalId.toString() === id);
}

function run(json) {
    const cmd = JSON.parse(json);
    if (cmd.op === "cursor") {
        // where the pointer is, and the app of the topmost window under it (autoscroll: anchor + per-app rule)
        const p = workspace.cursorPos;
        const under = workspace.stackingOrder.slice().reverse().find(w => !w.minimized && w.onCurrentDesktop !== false
            && (w.normalWindow || w.dialog) && p.x >= w.frameGeometry.x && p.x < w.frameGeometry.x + w.frameGeometry.width
            && p.y >= w.frameGeometry.y && p.y < w.frameGeometry.y + w.frameGeometry.height);
        callDBus("org.clockmost.KWinBridge", "/Bridge", "org.clockmost.KWinBridge", "Update",
            JSON.stringify({ event: "cursor", x: p.x, y: p.y, app: under ? under.resourceClass : "", tag: cmd.id }));
        return;
    }
    const w = findWindow(cmd.id);
    if (!w)
        return;
    if (cmd.op === "activate") {
        w.minimized = false;
        if (!w.onAllDesktops && !w.desktops.includes(workspace.currentDesktop))
            workspace.currentDesktop = w.desktops[0];
        workspace.activeWindow = w;
    } else if (cmd.op === "minimize") {
        w.minimized = true;
    } else if (cmd.op === "close") {
        w.closeWindow();
    }
}

function poll() {
    callDBus("org.clockmost.KWinBridge", "/Bridge", "org.clockmost.KWinBridge", "Next", json => {
        if (json) {
            try {
                run(json);
            } catch (e) {
                print("clockmost-bridge: bad command " + json + ": " + e);
            }
        }
        poll();
    });
}
poll();
