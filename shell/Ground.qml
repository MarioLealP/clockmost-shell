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
    // (Mario 2026-10-25: "just shift the orange bar, keep everything else still"). Motion: GroundLine + SectionStage.
    Item {
        id: pan
        visible: root.main
        width: parent.width
        height: parent.height

        GroundLine { id: line; targetX: HaSections.current !== "" ? 1620 : 920; y: -140; onAway: stage.lineAway() }

        SectionStage {
            id: stage
            x: 472 // on the grid (dots at x 16 + 24k, y 12 + 24k on 3440 x 1440)
            y: 108
            sections: ({
                ROOM: secRoom, MISC: secMisc, TODAY: secToday, NEWS: secNews,
                ENDER: secEnder, ELEGOO: secElegoo, SYSTEMS: secSystems
            })
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

        // along the bottom, right of the line, left of the hero; bottom edge on the 1260 dot row
        SystemReadout { x: 568; y: 1260 - height }

        HeroSlices { x: 1640; y: 125 }
        XMarks {}

        GroundBarcode { x: 96; anchors.bottom: parent.bottom; anchors.bottomMargin: 140 }
        DateStack { anchors.right: parent.right; anchors.rightMargin: 88; anchors.bottom: parent.bottom; anchors.bottomMargin: 132 } // right edge with the Felt column, baseline on a dot row
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
            targets: [["NOZZLE TARGET", "number.ender_set_nozzle_target", " °C"], ["BED TARGET", "number.ender_set_bed_target", " °C"]]
            groups: [
                [["PAUSE", "button.ender_pause"], ["RESUME", "button.ender_resume"], ["CANCEL", "button.ender_cancel_print", true]],
                [["PREHEAT PLA", "button.ender_preheat_pla"], ["NOZZLE CLEAN", "button.ender_nozzle_clean"], ["COOL DOWN", "button.ender_cool_down"]],
                [["HOME", "button.ender_home_all_axes"], ["MOTORS OFF", "button.ender_motors_off"], ["FIRMWARE RESTART", "button.ender_firmware_restart"], ["E-STOP", "button.ender_emergency_stop", true]]
            ]
        }
    }
    Component {
        id: secElegoo
        SecPrinter {
            title: "ELEGOO"; stateId: "sensor.3d_printer_status_atual"; progressId: "sensor.elegoo_progress"
            rows: [["FILE", "sensor.elegoo_file"], ["PRINT", "sensor.3d_printer_status_de_impressao"], ["LAYER", "sensor.3d_printer_current_layer"],
                ["OF", "sensor.3d_printer_total_layers"], ["LEFT", "sensor.3d_printer_remaining_print_time"], ["ENDS", "sensor.3d_printer_end_time"], ["UV LED", "sensor.3d_printer_uv_led_temp", " °C"],
                ["RELEASE FILM", "sensor.3d_printer_release_film", " / 60000"], ["ERROR", "sensor.3d_printer_razao_do_status_de_erro"], ["FIRMWARE", "update.3d_printer_firmware"]]
            coverId: "image.3d_printer_cover_image"
            groups: [[["PAUSE", "button.3d_printer_pause_print"], ["RESUME", "button.3d_printer_resume_print"], ["STOP", "button.3d_printer_stop_print", true]]]
        }
    }
    Component { id: secSystems; SecSystems {} }

    // fixed: the controls don't pan
    HaList { visible: root.main; x: 88; y: 108 } // two dots in from the corner mark, the row under it
    FeltColumn { visible: root.main; anchors.right: parent.right; anchors.rightMargin: 88; y: 108 } // mirrors the HA list
}
