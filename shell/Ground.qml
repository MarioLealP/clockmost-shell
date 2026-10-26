// The v2 desktop ("ground"): a Background layer surface under the windows, above plasmashell's desktop (spike
// 2026-10-25). The main screen gets the poster; side screens only the base, dots and corners (Mario: no line there).
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    property bool main: false

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "clockmost-ground"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    // the Felt talk box needs the keyboard when clicked
    WlrLayershell.keyboardFocus: root.main ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    anchors { left: true; right: true; top: true; bottom: true }
    color: GroundTheme.bg

    DotGrid {
        anchors.fill: parent
        pitch: 24
        radius: 1.2
        color: GroundTheme.line
    }

    RegMarks { anchors.fill: parent }

    // the poster. Opening an HA section only moves the orange line out of the way - everything else stays still
    // (Mario 2026-10-25: "just shift the orange bar, keep everything else still"). No motion yet: it jumps.
    Item {
        id: pan
        visible: root.main
        width: parent.width
        height: parent.height

        GroundLine { id: line; targetX: HaSections.current !== "" ? 1620 : 920; y: -140 }

        // the section shows once the line has left its resting spot (it would cross the section on its way out)
        Loader {
            x: 470
            y: 104
            active: HaSections.current !== "" && line.x > 1000
            sourceComponent: ({
                ROOM: secRoom, MISC: secMisc, TODAY: secToday, NEWS: secNews,
                ENDER: secEnder, ELEGOO: secElegoo, SYSTEMS: secSystems
            })[HaSections.current] ?? null
        }

        Text {
            x: 96
            y: 545
            text: "✖✖✖✖✖✖✖✖✖✖\n✖✖✖✖✖✖✖✖✖✖"
            color: GroundTheme.faint
            font.family: GroundTheme.display
            font.pixelSize: 40
            font.weight: Font.Black
            font.variableAxes: { "wght": 900 }
            font.letterSpacing: 2
            lineHeight: 0.8
        }

        HeroSlices { x: 1640; y: 125 }
        XMarks {}

        GroundBarcode { x: 96; anchors.bottom: parent.bottom; anchors.bottomMargin: 140 }
        DateStack { anchors.right: parent.right; anchors.rightMargin: 110; anchors.bottom: parent.bottom; anchors.bottomMargin: 150 }
    }

    Component { id: secRoom; SecRoom {} }
    Component { id: secMisc; SecMisc {} }
    Component { id: secToday; SecToday {} }
    Component { id: secNews; SecNews {} }
    Component {
        id: secEnder
        SecPrinter {
            title: "ENDER"; stateId: "sensor.ender_state"; progressId: "sensor.ender_progress"
            rows: [["FILE", "sensor.ender_file"], ["LAYER", "sensor.ender_layer"], ["ELAPSED", "sensor.ender_elapsed"],
                ["LEFT", "sensor.ender_time_left"], ["DONE AT", "sensor.ender_done_at"], ["NOZZLE", "sensor.ender_nozzle", " °C"], ["BED", "sensor.ender_bed", " °C"]]
        }
    }
    Component {
        id: secElegoo
        SecPrinter {
            title: "ELEGOO"; stateId: "sensor.3d_printer_status_atual"; progressId: "sensor.elegoo_progress"
            rows: [["FILE", "sensor.elegoo_file"], ["PRINT", "sensor.3d_printer_status_de_impressao"], ["LAYER", "sensor.3d_printer_current_layer"],
                ["OF", "sensor.3d_printer_total_layers"], ["LEFT", "sensor.3d_printer_remaining_print_time"], ["ENDS", "sensor.3d_printer_end_time"], ["UV LED", "sensor.3d_printer_uv_led_temp", " °C"]]
        }
    }
    Component { id: secSystems; SecSystems {} }

    // fixed: the controls don't pan
    HaList { visible: root.main; x: 84; y: 104 }
    FeltColumn { visible: root.main; anchors.right: parent.right; anchors.rightMargin: 96; y: 104 }
}
