// One label ...... value row (mono), the spec-sheet line used across the sections.
import QtQuick

Item {
    id: root

    property string label
    property string value
    property bool strong: false

    width: parent?.width ?? 560
    height: 30

    Text { anchors.verticalCenter: parent.verticalCenter; text: root.label; color: GroundTheme.ink2; font.family: GroundTheme.mono; font.pixelSize: 11; font.letterSpacing: 2 }
    Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(implicitWidth, parent.width - 160)
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideRight
        text: root.value
        color: root.strong ? GroundTheme.acc : GroundTheme.ink
        font.family: GroundTheme.mono
        font.pixelSize: 13
        font.letterSpacing: 1
    }
    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: GroundTheme.line }
}
