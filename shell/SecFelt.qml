// FELT: her switches + "talk" (the HA script the dashboard's say-card uses).
import QtQuick

Column {
    spacing: 18

    SecHead { title: "FELT"; meta: HaSections.felt(); onBack: HaSections.current = "" }

    Flow {
        width: 560
        spacing: 6
        SecToggle { entity: "switch.felt_quiet"; label: "QUIET" }
        SecToggle { entity: "switch.felt_hidden"; label: "HIDDEN" }
        SecToggle { entity: "switch.felt_dj_mode"; label: "DJ MODE" }
    }

    Rectangle {
        width: tt.implicitWidth + 30
        height: 40
        color: ma.containsMouse ? GroundTheme.acc : "transparent"
        border.width: 1.5
        border.color: GroundTheme.acc
        Text { id: tt; anchors.centerIn: parent; text: "→ TALK TO FELT"; color: ma.containsMouse ? GroundTheme.accInk : GroundTheme.acc; font.family: GroundTheme.mono; font.pixelSize: 12; font.letterSpacing: 2 }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: HaClient.call("script", "turn_on", "script.felt_talk") }
    }
}
