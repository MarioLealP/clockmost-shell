// Dev entry for the v2 ground only: `quickshell -p shell/ground-dev.qml` next to the installed shell.
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    // quickshell ipc --pid <pid> call ground open ROOM  /  ... close
    IpcHandler {
        target: "ground"
        function open(section: string): void { HaSections.current = section.toUpperCase(); }
        function close(): void { HaSections.current = ""; }
    }

    Variants {
        model: Quickshell.screens
        Ground {
            required property var modelData
            screen: modelData
            main: modelData.name === "DP-2"
        }
    }
}
