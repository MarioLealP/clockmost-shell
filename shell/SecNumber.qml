// A number entity as LABEL ... [−] value [+] (the dashboard's numeric-input buttons): steps
// within its min/max (5 at a time, or the step if bigger), number.set_value.
import QtQuick

Item {
    id: root

    property string label
    property string entity
    property string unit: ""
    readonly property real value: Number(HaClient.st(entity)) || 0
    readonly property real step: HaClient.attr(entity, "step") ?? 1
    readonly property real min: HaClient.attr(entity, "min") ?? 0
    readonly property real max: HaClient.attr(entity, "max") ?? 300

    function set(v) {
        HaClient.call("number", "set_value", entity, { value: Math.max(min, Math.min(max, v)) });
    }

    width: parent?.width ?? 560
    height: 40

    Text { anchors.verticalCenter: parent.verticalCenter; text: root.label; color: GroundTheme.ink2; font.family: GroundTheme.mono; font.pixelSize: 11; font.letterSpacing: 2 }
    Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0
        Step { glyph: "−"; onHit: root.set(root.value - Math.max(root.step, 5)) }
        Text {
            width: 96
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignHCenter
            text: HaClient.st(root.entity) === "" ? "--" : Math.round(root.value) + root.unit
            color: GroundTheme.ink
            font.family: GroundTheme.display
            font.pixelSize: 22
            font.weight: Font.ExtraBold
            font.variableAxes: { "wdth": 80, "wght": 800 }
        }
        Step { glyph: "+"; onHit: root.set(root.value + Math.max(root.step, 5)) }
    }
    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: GroundTheme.line }

    component Step: Rectangle {
        id: s
        property string glyph
        signal hit
        width: 32
        height: 28
        color: sm.containsMouse ? GroundTheme.acc : "transparent"
        border.width: 1.5
        border.color: sm.containsMouse ? GroundTheme.acc : GroundTheme.line
        Text { anchors.centerIn: parent; text: s.glyph; color: sm.containsMouse ? GroundTheme.accInk : GroundTheme.ink; font.family: GroundTheme.mono; font.pixelSize: 14 }
        MouseArea { id: sm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: s.hit() }
    }
}
