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
        property bool slash: false
        property color tint: GroundTheme.ink
        anchors.right: parent.right
        width: t.implicitWidth
        height: 94 // the poster's tight 0.84 line height: the glyphs overflow the row on purpose
        Text {
            id: t
            anchors.bottom: parent.bottom
            anchors.bottomMargin: -18
            text: parent.text
            color: parent.tint
            font.family: GroundTheme.display
            font.pixelSize: 112
            font.weight: Font.Black
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

    component Small: Text {
        anchors.right: parent.right
        topPadding: 16
        bottomPadding: 26
        color: GroundTheme.ink2
        font.family: GroundTheme.mono
        font.pixelSize: 12
        font.letterSpacing: 3
    }

    Big { text: Weather.ready ? Weather.temperature + "°" : "--°" }
    Small { text: Weather.ready ? (Weather.city + "  ·  " + Weather.condition).toUpperCase() : "LOCATING" }
    // dd / mm / yyyy - European order (Mario 2026-10-25), the year split over two rows
    Big { text: Qt.formatDate(clock.date, "dd"); slash: true }
    Big { text: Qt.formatDate(clock.date, "MM"); slash: true }
    Big { text: Qt.formatDate(clock.date, "yyyy").slice(0, 2) }
    Big { text: Qt.formatDate(clock.date, "yyyy").slice(2) }
    Text {
        anchors.right: parent.right
        topPadding: 18
        bottomPadding: 26
        text: "[" + Qt.formatDate(clock.date, "ddd").toUpperCase() + "]"
        color: GroundTheme.ink
        font.family: GroundTheme.display
        font.pixelSize: 44
        font.weight: Font.Black
    }
    Big { text: "→" + Qt.formatTime(clock.date, "hh"); slash: true; tint: GroundTheme.acc }
    Big { text: Qt.formatTime(clock.date, "mm"); tint: GroundTheme.acc }
}
