// The control center's vertical tab rail (Noctalia-style switching, Endfield parts): each tab is an icon cell;
// the active one gets the Dolphin-mock treatment - a faint white wash + a 3px yellow tick on the left.
import QtQuick

Column {
    id: root

    width: 52
    topPadding: 10
    spacing: 2

    Repeater {
        model: ControlCenter.tabs
        Item {
            id: cell
            required property var modelData
            required property int index
            readonly property bool active: ControlCenter.tab === modelData.id
            width: root.width
            height: 46

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(1, 1, 1, cell.active ? 0.06 : area.containsMouse ? 0.035 : 0)
                Behavior on color { ColorAnimation { duration: 140 } }
            }
            Rectangle {
                width: 3
                height: parent.height
                color: Theme.yellow
                opacity: cell.active ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 140 } }
            }
            Glyph {
                anchors.centerIn: parent
                path: Icons.byName(cell.modelData.icon)
                color: cell.active ? Theme.yellow : area.containsMouse ? Theme.ink : Theme.dim
            }
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 5
                y: 4
                text: String(cell.index + 1).padStart(2, "0")
                color: cell.active ? "#d8d36a" : "#43454c"
                font.family: Theme.mono
                font.pixelSize: 7
                font.letterSpacing: Theme.em(7, 0.1)
            }
            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ControlCenter.tab = cell.modelData.id
            }
        }
    }
}
