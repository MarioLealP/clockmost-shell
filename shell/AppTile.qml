// One drawer tile (the mock's: 120px, 6px corners, inset shadow, faint topo, logo or letter, mono name,
// code on top, a colour underbar). Selected = yellow outline.
import QtQuick
import Quickshell

Item {
    id: root

    required property var entry
    property bool selected: false
    readonly property string iconSource: entry.icon ? Quickshell.iconPath(entry.icon, true) : ""
    signal activated

    width: 120
    height: 120

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: area.containsMouse || root.selected ? Qt.rgba(84 / 255, 88 / 255, 98 / 255, 0.65) : Qt.rgba(70 / 255, 74 / 255, 82 / 255, 0.5)
        border.width: root.selected ? 2 : 1
        border.color: root.selected ? Theme.yellow : Qt.rgba(0, 0, 0, 0.35)
        clip: true
        Behavior on color { ColorAnimation { duration: 120 } }

        Image {
            anchors.fill: parent
            source: Qt.resolvedUrl("assets/topo-plate.svg")
            fillMode: Image.PreserveAspectCrop
            sourceSize.height: 240
            opacity: 0.12
        }
        // inset shadow at the top edge
        Rectangle {
            width: parent.width
            height: 10
            radius: 6
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.rgba(0, 0, 0, 0.35) }
                GradientStop { position: 1; color: "transparent" }
            }
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 7
        text: "· " + Apps.code(root.entry)
        color: "#6c6f76"
        font.family: Theme.mono
        font.pixelSize: 10
        font.letterSpacing: Theme.em(10, 0.22)
    }

    Image {
        id: icon
        anchors.horizontalCenter: parent.horizontalCenter
        y: 30
        width: 52
        height: 52
        sourceSize.width: 104
        sourceSize.height: 104
        source: root.iconSource
        visible: status === Image.Ready
        smooth: true
    }
    Text {
        visible: !icon.visible
        anchors.horizontalCenter: parent.horizontalCenter
        y: 38
        text: root.entry.name.charAt(0).toUpperCase()
        color: "#e8e9ec"
        font.family: Theme.body
        font.weight: Font.Bold
        font.pixelSize: 29
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 90
        width: parent.width - 12
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: root.entry.name
        color: "#e8e9ec"
        font.family: Theme.mono
        font.weight: Font.DemiBold
        font.pixelSize: 13
        font.letterSpacing: Theme.em(13, 0.08)
    }

    Rectangle {
        anchors.bottom: parent.bottom
        x: 1
        width: parent.width - 2
        height: 3
        color: AppColors.of(root.entry.name)
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
