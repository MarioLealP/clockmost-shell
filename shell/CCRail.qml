// The control center's vertical tab rail (v2): an icon per tab, the active one an orange square.
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

            // v2: the active tab is an orange square with a dark glyph; no tick, no index
            Rectangle {
                anchors.centerIn: parent
                width: 38
                height: 38
                color: cell.active ? GroundTheme.acc : area.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
            }
            Glyph {
                anchors.centerIn: parent
                path: Icons.byName(cell.modelData.icon)
                color: cell.active ? GroundTheme.accInk : area.containsMouse ? Theme.ink : Theme.dim
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
