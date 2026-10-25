// .left: CLOCKMOST mark, workspace chips (v2: the Felt chip left - her column on the ground has it).
import QtQuick

Row {
    spacing: 14

    BarMark {
        anchors.verticalCenter: parent.verticalCenter
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6
        Repeater {
            model: KWin.desktops
            WorkspaceChip {
                required property var modelData
                desktop: modelData
            }
        }
    }
}
