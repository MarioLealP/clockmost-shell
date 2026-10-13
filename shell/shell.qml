// clockmost-shell entry point: one Endfield bar + control center per screen.
// IPC (keybinds, scripts): quickshell ipc --pid <pid> call controlcenter open|toggle <tab>  /  ... close
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    IpcHandler {
        target: "controlcenter"
        function open(tab: string): void { ControlCenter.show(tab, ""); }
        function toggle(tab: string): void { ControlCenter.toggle(tab, ""); }
        function openAt(tab: string, x: real): void { ControlCenter.show(tab, "", x); }
        function close(): void { ControlCenter.close(); }
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
        }
    }
}
