// The v2 desktop ("ground"): a Background layer surface under the windows, above plasmashell's desktop (spike
// 2026-10-25). The main screen gets the poster; side screens only the base, dots and corners (Mario: no line there).
// At startup it builds in (boot phase 2, Mario 2026-10-28: "first the grey background, then the dots, then load stuff
// in"): the graphite is there at once, the dots spread out from the centre, the corners come, the line lands, then the
// pieces rise in from left to right. Replay: ipc call ground intro.
import QtQuick
import QtQuick.Effects
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

    // ---- the startup build-in ----
    property real dotsP: 0 // the dots' circle, 0 = none .. 1 = past the corners
    property real marksP: 0
    property real pieces: 0 // how many pieces are in (each takes one unit to rise in)
    // the piece at place k (left to right): 0 = waiting .. 1 = in
    function piece(k) {
        return Math.max(0, Math.min(1, pieces - k));
    }
    SequentialAnimation {
        id: intro
        ScriptAction { script: { root.dotsP = 0; root.marksP = 0; root.pieces = 0; line.split = 1; } }
        NumberAnimation { target: root; property: "dotsP"; to: 1; duration: 900; easing.type: Easing.InOutCubic }
        NumberAnimation { target: root; property: "marksP"; to: 1; duration: 260; easing.type: Easing.OutCubic }
        ScriptAction { script: line.enter() }
        PauseAnimation { duration: 280 }
        NumberAnimation { target: root; property: "pieces"; to: 8; duration: 1100 }
    }
    Component.onCompleted: intro.restart()
    Connections {
        target: GroundTheme
        function onIntroPokesChanged() { intro.restart(); }
    }

    Item {
        anchors.fill: parent
        layer.enabled: root.dotsP < 1
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: dotsMask
        }
        DotGrid {
            anchors.fill: parent
            pitch: 24
            radius: 1.2
            color: GroundTheme.line
        }
    }
    // the dots' reveal: a circle growing from the centre (the login ended there)
    Item {
        id: dotsMask
        anchors.fill: parent
        layer.enabled: true
        visible: false
        Rectangle {
            readonly property real r: root.dotsP * Math.hypot(root.width, root.height) / 2
            x: root.width / 2 - r
            y: root.height / 2 - r
            width: r * 2
            height: r * 2
            radius: r
        }
    }

    RegMarks {
        anchors.fill: parent
        opacity: root.marksP
    }

    // a press on the bare ground closes the app drawer (its input is only its own panel)
    MouseArea {
        anchors.fill: parent
        onPressed: mouse => {
            Drawer.close();
            mouse.accepted = false;
        }
    }

    // the poster. Opening an HA section only moves the orange line out of the way - everything else stays still
    // (Mario 2026-10-25: "just shift the orange bar, keep everything else still"). Motion: GroundLine + SectionStage.
    Item {
        id: pan
        visible: root.main
        width: parent.width
        height: parent.height

        GroundLine {
            id: line
            targetX: HaSections.current !== "" ? 1620 : 920
            y: -140
            onAway: stage.lineAway()
        }

        SectionStage {
            id: stage
            opacity: root.piece(5)
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
            opacity: root.piece(1)
            transform: Translate { y: (1 - root.piece(1)) * 16 }
            text: "✖✖✖✖✖✖✖✖✖✖\n✖✖✖✖✖✖✖✖✖✖"
            color: GroundTheme.faint
            font.family: GroundTheme.display
            font.pixelSize: 40
            font.weight: Font.Black
            font.variableAxes: { "wght": 900 }
            font.letterSpacing: 2
            lineHeight: 0.8
        }


        HeroSlices { x: 1640; y: 125; opacity: root.piece(3); transform: Translate { y: (1 - root.piece(3)) * 16 } }
        XMarks { opacity: root.piece(4); transform: Translate { y: (1 - root.piece(4)) * 16 } }

        GroundBarcode { x: 96; anchors.bottom: parent.bottom; anchors.bottomMargin: 140; opacity: root.piece(2); transform: Translate { y: (1 - root.piece(2)) * 16 } }
        DateStack { anchors.right: parent.right; anchors.rightMargin: 88; anchors.bottom: parent.bottom; anchors.bottomMargin: 132; opacity: root.piece(6); transform: Translate { y: (1 - root.piece(6)) * 16 } } // right edge with the Felt column, baseline on a dot row
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
    HaList { visible: root.main; x: 88; y: 108; opacity: root.piece(0); transform: Translate { y: (1 - root.piece(0)) * 16 } } // two dots in from the corner mark, the row under it
    FeltColumn { visible: root.main; anchors.right: parent.right; anchors.rightMargin: 88; y: 108; opacity: root.piece(7); transform: Translate { y: (1 - root.piece(7)) * 16 } } // mirrors the HA list
}
