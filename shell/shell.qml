// clockmost-shell entry point: one Endfield bar + control center per screen.
// IPC (keybinds, scripts): quickshell ipc --pid <pid> call controlcenter open|toggle <tab>  /  ... close
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    IpcHandler {
        target: "controlcenter"
        function open(tab: string): void { ControlCenter.show(tab, ""); }
        function toggle(tab: string): void { ControlCenter.toggle(tab, ""); }
        function openAt(tab: string, x: real): void { ControlCenter.show(tab, "", x); }
        function close(): void { ControlCenter.close(); }
    }

    // debugging: what the shell currently believes about KWin's windows
    IpcHandler {
        target: "kwin"
        function windows(): string { return JSON.stringify(KWin.windows.map(w => ({ app: w.app, active: w.active, minimized: w.minimized }))); }
    }

    IpcHandler {
        target: "dock"
        function preview(key: string): void { DockApps.forcedPreview = key; }
    }

    IpcHandler {
        target: "drawer"
        function toggle(): void { Drawer.toggle(); }
        function open(): void { Drawer.open = true; }
        function close(): void { Drawer.close(); }
    }

    // Win+V (KWin script shortcut). Here, not in Clipboard: a singleton only exists once something uses it, so a
    // listener inside it would miss the first press after a (re)start
    Connections {
        target: KWin
        function onClipboardRequested(x, y) {
            Clipboard.openAtPointer(x, y);
        }
    }

    // v2: the ground (desktop layer) on every screen - the poster on the ultrawide.
    // Off switch: ~/.config/clockmost/ground-off exists = no ground (Plasma's desktop shows), the rest stays.
    // Checked every 10 s, so creating / deleting the file takes effect without a restart.
    property bool groundOff: false
    Process {
        id: groundSwitch
        command: ["test", "-e", Quickshell.env("HOME") + "/.config/clockmost/ground-off"]
        running: true
        onExited: code => root.groundOff = code === 0
    }
    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: groundSwitch.running = true
    }
    IpcHandler {
        target: "ground"
        function open(section: string): void { HaSections.current = section.toUpperCase(); }
        function close(): void { HaSections.current = ""; }
        function art(): void { HeroArt.next(); } // swap the hero's picture now
        function marks(): void { HeroArt.markPokes++; } // the X marks' re-strike + focus pull now
    }
    Variants {
        model: root.groundOff ? [] : Quickshell.screens
        Ground {
            required property var modelData
            screen: modelData
            main: modelData.name === "DP-2"
        }
    }

    // the app drawer and notification popups live on the first screen
    DrawerWindow {
        screen: Quickshell.screens[0]
    }

    // notification popups on the first screen
    NotifPopups {
        screen: Quickshell.screens[0]
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: perScreen
            required property var modelData
            Bar {
                screen: perScreen.modelData
            }
            CCWindow {
                screen: perScreen.modelData
            }
            TrayMenuWindow {
                screen: perScreen.modelData
            }
            DockMenuWindow {
                screen: perScreen.modelData
            }
            DockWindow {
                screen: perScreen.modelData
            }
            AutoscrollMarker {
                output: perScreen.modelData
            }
            // outside clicks on the screens the drawer isn't on
            LazyLoader {
                active: perScreen.modelData !== Quickshell.screens[0]
                DrawerCatcher {
                    screen: perScreen.modelData
                }
            }
        }
    }
}
