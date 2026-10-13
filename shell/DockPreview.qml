// Hover preview for a dock slot (Mario: "show me the open windows like in windows"): the app's windows as live
// ds-alttab-v2 cards, so you can see what a click will do. Built from the alt-tab mock:
// Tightened (Mario: "a bit more tidy and tight"): the panel wears the dock's own plate (DockPlate: band material,
// ruler, brackets) + 0 20px 60px rgba(0,0,0,.45) and KWin blur, 12px padding, a pointer down to the hovered tile;
// cards 220x186 at 1:1, 10px apart, one row of up to 5.
//   .grp .gl  12px mono .14em: <b>APP</b> - 1px line - 10px count; 12px above cards. The mock's #33363C ink sits on
//             the alt-tab's light glass under its white head; this panel has no head, so the ink is the light
//             pair (#c9ccd3 / rgba(241,241,244,.2) / #7d8089) - dark ink vanished on the dark glass
import QtQuick
import QtQuick.Effects
import Quickshell

Item {
    id: root

    property var slot: null
    readonly property var wins: slot ? slot.windows.slice(0, 5) : []
    property real pointerX: width / 2 // where the hovered tile is, in panel coordinates
    readonly property alias hovered: hover.hovered
    property string icon: ""

    width: inner.width + 24
    height: inner.height + 26

    HoverHandler {
        id: hover
    }

    RectangularShadow {
        anchors.fill: parent
        offset.y: 20
        blur: 60
        radius: 2
        color: Qt.rgba(0, 0, 0, 0.45)
    }
    DockPlate {
        anchors.fill: parent
    }
    // pointer to the tile: the plate's colour, its border on the two lower edges
    Item {
        x: Math.max(12, Math.min(root.width - 22, root.pointerX - 5))
        y: root.height - 5
        width: 10
        height: 10
        rotation: 45
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(16 / 255, 17 / 255, 20 / 255, 0.95)
        }
        Rectangle {
            anchors.right: parent.right
            width: 1
            height: parent.height
            color: Qt.rgba(1, 1, 1, 0.12)
        }
        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: Qt.rgba(1, 1, 1, 0.12)
        }
    }

    Column {
        id: inner
        x: 12
        y: 14 // clears the plate's 7px ruler
        spacing: 8

        // .gl
        Row {
            width: cards.width
            spacing: 8
            Text {
                id: gl
                text: root.slot ? root.slot.name.toUpperCase() : ""
                color: Theme.ink2
                font.family: Theme.mono
                font.weight: Font.Bold
                font.pixelSize: 12
                font.letterSpacing: Theme.em(12, 0.14)
            }
            Rectangle {
                anchors.verticalCenter: gl.verticalCenter
                width: Math.max(0, cards.width - gl.width - now.width - 16)
                height: 1
                color: Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.2)
            }
            Text {
                id: now
                anchors.verticalCenter: gl.verticalCenter
                text: {
                    const n = root.slot ? root.slot.windows.length : 0;
                    return n + (n === 1 ? " WINDOW" : " WINDOWS") + (n > 5 ? " · 5 SHOWN" : "");
                }
                color: Theme.dim
                font.family: Theme.mono
                font.pixelSize: 10
                font.letterSpacing: Theme.em(10, 0.14)
            }
        }

        Row {
            id: cards
            spacing: 10
            Repeater {
                model: root.wins
                WindowCard {
                    required property var modelData
                    win: modelData
                    icon: root.icon
                    c: root.slot ? AppColors.of(root.slot.app) : Theme.cyan
                    onActivated: KWin.command("activate", modelData.id)
                }
            }
        }
    }
}
