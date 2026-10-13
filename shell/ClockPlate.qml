// The hanging yellow clock plate (the one bright yellow) + the tri-band under it.
import QtQuick
import QtQuick.Effects
import Quickshell

Item {
    id: root

    width: Theme.plateWidth
    height: Theme.plateHeight + Theme.triBand

    function utcOffset(d) {
        const minutes = -d.getTimezoneOffset();
        const h = Math.floor(Math.abs(minutes) / 60), m = Math.abs(minutes) % 60;
        return (minutes < 0 ? "-" : "+") + h + (m ? ":" + String(m).padStart(2, "0") : "");
    }

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    RectangularShadow {
        anchors.fill: plate
        offset.y: 10
        blur: 30
        color: Qt.rgba(0, 0, 0, 0.45)
    }

    Rectangle {
        id: plate
        width: Theme.plateWidth
        height: Theme.plateHeight
        color: Theme.yellow
        clip: true

        // topo lines inside the plate, darker yellow
        Image {
            anchors.fill: parent
            source: Qt.resolvedUrl("assets/topo-plate.svg")
            fillMode: Image.PreserveAspectCrop // CSS object-fit: cover
            sourceSize.height: Theme.plateHeight * 2
            opacity: 0.22 // strokes are plain #111 + stroke-opacity: QtSvg (SVG Tiny) ignores rgba() colours
        }

        Hatch {
            x: 0
            y: 0
            width: 64
            height: 22
            color: Qt.rgba(0.067, 0.067, 0.067, 0.55)
            line: 2
            pitch: 6 // CSS: 2px line every 6px
        }

        DotGrid {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 26
            width: 54
            height: 30
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 12
            y: 8
            text: ":" + Qt.formatDateTime(clock.date, "ss")
            color: Theme.plateInk
            opacity: 0.6
            font.family: Theme.mono
            font.weight: Font.Bold
            font.pixelSize: 9
            font.letterSpacing: Theme.em(9, 0.16)
        }

        // 20:41 - colon dimmed; .14em tracking, padded left by the same so it stays centred
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: Theme.em(40, 0.14) / 2
            y: 12 // CSS top 18 with line-height 1; Qt's box adds the font's ascent above the digits
            Repeater {
                model: [Qt.formatDateTime(clock.date, "hh"), ":", Qt.formatDateTime(clock.date, "mm")]
                Text {
                    required property string modelData
                    text: modelData
                    color: Theme.plateInk
                    opacity: modelData === ":" ? 0.55 : 1
                    font.family: Theme.mono
                    font.weight: Font.Bold
                    font.pixelSize: 40
                    font.letterSpacing: Theme.em(40, 0.14)
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 62
            spacing: 10
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDateTime(clock.date, "ddd").toUpperCase()
                color: Theme.plateInk
                font.family: Theme.mono
                font.weight: Font.Bold
                font.pixelSize: 10
                font.letterSpacing: Theme.em(10, 0.26)
            }
            Barcode {
                anchors.verticalCenter: parent.verticalCenter
                width: 40
                height: 7
                color: Theme.plateInk
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDateTime(clock.date, "dd MMM yyyy").toUpperCase()
                color: Theme.plateInk
                font.family: Theme.mono
                font.weight: Font.Bold
                font.pixelSize: 10
                font.letterSpacing: Theme.em(10, 0.26)
            }
        }

        Text {
            x: 12
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            // CLK-<month day> · UTC<offset>
            text: "CLK-" + Qt.formatDateTime(clock.date, "MMdd") + " · UTC" + root.utcOffset(clock.date)
            color: Theme.plateInk
            opacity: 0.5
            font.family: Theme.mono
            font.weight: Font.Bold
            font.pixelSize: 8
            font.letterSpacing: Theme.em(8, 0.18)
        }
    }

    // the one tri-band, hanging under the plate
    Row {
        y: Theme.plateHeight
        Rectangle { width: Theme.plateWidth / 3; height: Theme.triBand; color: Theme.yellow }
        Rectangle { width: Theme.plateWidth / 3; height: Theme.triBand; color: Theme.cyan }
        Rectangle { width: Theme.plateWidth / 3; height: Theme.triBand; color: Theme.magenta }
    }
}
