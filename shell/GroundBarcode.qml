// Barcode built from the date + time digits, with the readable stamp under it: changes every minute.
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
                    readonly property int n: Number(root.digits[Math.floor(index / 4)])
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
    }

    Text {
        text: Qt.formatDateTime(clock.date, "dd.MM.yyyy  ·  hh:mm")
        color: GroundTheme.ink2
        font.family: GroundTheme.mono
        font.pixelSize: 11
        font.letterSpacing: 3
    }
}
