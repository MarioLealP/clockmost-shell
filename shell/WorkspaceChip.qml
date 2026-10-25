// One chip per desktop on the workspace plate (v2): the active one is an orange slab.
// Under the number, one 8x3 mark per window, in that app's colour. Click = switch to it.
import QtQuick

Item {
    id: root

    required property var desktop // {id, name, number}
    readonly property bool active: KWin.current === desktop.id
    readonly property var windows: KWin.windowsOn(desktop.id)

    width: 44
    height: 38

    // v2: the active desktop is an orange slab on the plate; the others are dark numbers
    Rectangle {
        anchors.fill: parent
        color: root.active ? GroundTheme.acc : (area.containsMouse ? Qt.rgba(0, 0, 0, 0.08) : "transparent")
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 6
        text: String(root.desktop.number).padStart(2, "0")
        color: root.active ? GroundTheme.accInk : Qt.rgba(0.1, 0.1, 0.09, 0.55)
        font.family: GroundTheme.mono
        font.weight: Font.Bold
        font.pixelSize: 13
    }
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 5
        spacing: 3
        Repeater {
            model: root.windows.slice(0, 5)
            Rectangle {
                required property var modelData
                width: 8
                height: 3
                color: root.active ? GroundTheme.accInk : GroundTheme.bg // v2: dark marks on the bone plate
                opacity: modelData.minimized ? 0.4 : 1
            }
        }
    }

    AttentionPin {
        visible: root.windows.some(w => w.attention)
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: KWin.switchTo(root.desktop.id)
    }
}
