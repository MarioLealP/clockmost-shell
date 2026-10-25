// Dev entry for the v2 ground only: `quickshell -p shell/ground-dev.qml` next to the installed shell.
import QtQuick
import Quickshell

ShellRoot {
    Variants {
        model: Quickshell.screens
        Ground {
            required property var modelData
            screen: modelData
            main: modelData.name === "DP-2"
        }
    }
}
