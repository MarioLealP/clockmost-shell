// .left: CLOCKMOST mark, workspace chips (v2: the Felt chip left - her column on the ground has it).
import QtQuick

Row {
    spacing: 6

    BarMark {
        anchors.verticalCenter: parent.verticalCenter
    }

    Plate {
        pad: 7
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            Repeater {
                model: KWin.desktops
                WorkspaceChip {
                    required property var modelData
                    desktop: modelData
                }
            }
        }
    }
}
