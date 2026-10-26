// Barcode built from the date + time digits, with the readable stamp under it: changes every minute. The change is a
// scan: an orange line sweeps left to right, the bars behind it already the new code, the stamp rolls.
import QtQuick
import Quickshell

Column {
    id: root

    spacing: 6

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property string digits: Qt.formatDateTime(clock.date, "ddMMyyyyhhmm")
    property string old: digits
    property real sweep: 1 // 0..1 across the bars; bars left of it show the new code

    onDigitsChanged: scan.restart()
    SequentialAnimation {
        id: scan
        NumberAnimation { target: root; property: "sweep"; from: 0; to: 1; duration: 480; easing.type: Easing.InOutQuad }
        ScriptAction { script: root.old = root.digits }
    }

    Rectangle {
        // the line runs behind the barcode, never through it
        width: bars.width + 10
        height: 46
        x: -5
        color: GroundTheme.bg

        Row {
            id: bars
            x: 5
            height: parent.height
            Repeater {
                model: root.digits.length * 4
                Item {
                    required property int index
                    readonly property bool fresh: (index + 0.5) / (root.digits.length * 4) < root.sweep
                    readonly property int n: Number((fresh ? root.digits : root.old)[Math.floor(index / 4)])
                    readonly property int k: index % 4
                    width: bar.width + 2 + ((n + k) % 3)
                    height: bars.height
                    Rectangle {
                        id: bar
                        width: 1 + ((n >> k) & 1) * 3
                        height: parent.height
                        color: GroundTheme.ink
                    }
                }
            }
        }
        Rectangle {
            visible: root.sweep < 1
            x: 5 + bars.width * root.sweep - 1
            width: 2
            height: parent.height + 8
            y: -4
            color: GroundTheme.acc
        }
    }

    RollText {
        value: Qt.formatDateTime(clock.date, "dd.MM.yyyy  ·  hh:mm")
        color: GroundTheme.ink2
        font.family: GroundTheme.mono
        font.pixelSize: 11
        font.letterSpacing: 3
    }
}
