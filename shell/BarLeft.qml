// .left: CLOCKMOST mark, Felt chip, workspace chips.
import QtQuick

Row {
    spacing: 14

    BarMark {
        anchors.verticalCenter: parent.verticalCenter
    }

    FeltChip {
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
