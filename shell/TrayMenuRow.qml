// One app-tray menu row: separator = a 1px rule; else [check/radio] [icon] text [› for submenus]. 28px tall,
// Inter 12 on the light ink, hover = 6% white + full ink, disabled = faint. Checks: a yellow square (radio: diamond).
import QtQuick
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    property QsMenuEntry entry: null
    property string label: entry ? entry.text.replace(/&(?!&)/g, "") : "" // drop the mnemonic markers
    property bool mono: false
    property bool separator: entry ? entry.isSeparator : false // settable: the dock menu's rows have no entry
    readonly property bool enabledEntry: entry ? entry.enabled : true
    readonly property int buttonType: entry ? entry.buttonType : QsMenuButtonType.None
    readonly property bool checked: entry ? entry.checkState === Qt.Checked : false
    signal activated

    height: separator ? 9 : 28

    Rectangle {
        visible: root.separator
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 1
        color: Qt.rgba(1, 1, 1, 0.10)
    }

    Rectangle {
        visible: !root.separator
        anchors.fill: parent
        color: Qt.rgba(1, 1, 1, area.containsMouse && root.enabledEntry ? 0.06 : 0)
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    Row {
        visible: !root.separator
        anchors.verticalCenter: parent.verticalCenter
        x: 8
        spacing: 8

        // check / radio
        Item {
            visible: root.buttonType !== QsMenuButtonType.None
            anchors.verticalCenter: parent.verticalCenter
            width: 10
            height: 10
            Rectangle {
                anchors.centerIn: parent
                width: 8
                height: 8
                rotation: root.buttonType === QsMenuButtonType.RadioButton ? 45 : 0
                color: root.checked ? Theme.yellow : "transparent"
                border.width: 1
                border.color: root.checked ? Theme.yellow : Theme.dim
            }
        }
        IconImage {
            visible: root.entry !== null && root.entry.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            implicitSize: 14
            source: root.entry ? root.entry.icon : ""
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: !root.enabledEntry ? Theme.faint : area.containsMouse ? Theme.ink : Theme.ink2
            font.family: root.mono ? Theme.mono : Theme.body
            font.pixelSize: root.mono ? 10 : 12
            font.letterSpacing: root.mono ? Theme.em(10, 0.18) : 0
        }
    }

    Text {
        visible: !root.separator && root.entry !== null && root.entry.hasChildren
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 8
        text: "›"
        color: Theme.dim
        font.family: Theme.body
        font.pixelSize: 14
    }

    MouseArea {
        id: area
        visible: !root.separator
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.enabledEntry ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (root.enabledEntry) root.activated()
    }
}
