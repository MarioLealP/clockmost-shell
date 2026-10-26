// Weather + date + time as one stacked poster column, right-aligned (the bar clock lives here in v2).
import QtQuick
import Quickshell

Column {
    id: root

    spacing: 0

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    component Big: Item {
        property string text
        property int delay: 0
        property bool slash: false
        property color tint: GroundTheme.ink
        anchors.right: parent.right
        width: t.implicitWidth
        height: 94 // the poster's tight 0.84 line height: the glyphs overflow the row on purpose
        RollText {
            id: t
            anchors.bottom: parent.bottom
            anchors.bottomMargin: -18
            value: parent.text
            delay: parent.delay
            color: parent.tint
            font.family: GroundTheme.display
            font.pixelSize: 112
            font.weight: Font.Black
            font.variableAxes: { "wght": 900 }
            font.letterSpacing: -3
        }
        Rectangle {
            visible: parent.slash
            x: parent.width + 30
            y: parent.height - 94
            width: 4
            height: 92
            color: parent.tint
            rotation: 35
        }
    }

    component Small: RollText {
        anchors.right: parent.right
        topPadding: 16
        bottomPadding: 26
        color: GroundTheme.ink2
        font.family: GroundTheme.mono
        font.pixelSize: 12
        font.letterSpacing: 3
    }

    Big { text: Weather.ready ? Weather.temperature + "°" : "--°" }
    Small { value: Weather.ready ? (Weather.city + "  ·  " + Weather.condition).toUpperCase() : "LOCATING" }
    // dd / mm / yyyy - European order (Mario 2026-10-25), the year split over two rows
    // at midnight these roll one after another down the column
    Big { text: Qt.formatDate(clock.date, "dd"); slash: true }
    Big { text: Qt.formatDate(clock.date, "MM"); slash: true; delay: 90 }
    Big { text: Qt.formatDate(clock.date, "yyyy").slice(0, 2); delay: 180 }
    Big { text: Qt.formatDate(clock.date, "yyyy").slice(2); delay: 270 }
    RollText {
        anchors.right: parent.right
        topPadding: 18
        bottomPadding: 26
        delay: 360
        value: "[" + Qt.formatDate(clock.date, "ddd").toUpperCase() + "]"
        color: GroundTheme.ink
        font.family: GroundTheme.display
        font.pixelSize: 44
        font.weight: Font.Black
        font.variableAxes: { "wght": 900 }
    }
    Big { text: "→" + Qt.formatTime(clock.date, "hh"); slash: true; tint: GroundTheme.acc }
    Big { text: Qt.formatTime(clock.date, "mm"); tint: GroundTheme.acc; delay: 60 }
}
