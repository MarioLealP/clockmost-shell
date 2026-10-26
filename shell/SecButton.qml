// A press button for the sections (HA button.press and the like). danger = arm first: one click turns it orange
// ("SURE?"), a second click within 3 s fires, otherwise it disarms - the dashboard's confirmation, without a dialog.
import QtQuick

Rectangle {
    id: root

    property string label
    property bool danger: false
    property bool armed: false
    signal fired

    width: t.implicitWidth + 26
    height: 36
    color: armed ? GroundTheme.acc : ma.pressed ? GroundTheme.ink : ma.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : GroundTheme.bg
    border.width: 1.5
    border.color: armed ? GroundTheme.acc : root.danger ? Qt.rgba(1, 95 / 255, 31 / 255, 0.6) : GroundTheme.line

    Text {
        id: t
        anchors.centerIn: parent
        text: root.armed ? "SURE?  ·  " + root.label : root.label
        color: root.armed ? GroundTheme.accInk : ma.pressed ? GroundTheme.bg : root.danger ? GroundTheme.acc : GroundTheme.ink
        font.family: GroundTheme.mono
        font.pixelSize: 11
        font.letterSpacing: 2
    }
    Timer {
        id: disarm
        interval: 3000
        onTriggered: root.armed = false
    }
    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.danger && !root.armed) {
                root.armed = true;
                disarm.restart();
                return;
            }
            root.armed = false;
            disarm.stop();
            root.fired();
        }
    }
}
