// The second, smaller art window: a letterbox along the bottom between the orange line and the hero (Mario
// 2026-10-26: the stretch was empty, "decoration only"). Another picture from the folder, swapping with the hero.
import QtQuick

Item {
    id: root

    width: 912
    height: 216

    Rectangle {
        anchors.fill: parent
        anchors.margins: -6
        color: "transparent"
        border.width: 2
        border.color: GroundTheme.ink
    }
    HalftoneArt {
        anchors.fill: parent
        delay: 1200
    }
    // a hazard strip off the top-left corner, like the hero's
    Rectangle {
        x: -30
        y: -46
        width: 240
        height: 24
        color: "transparent"
        clip: true
        Row {
            x: -30
            spacing: 14
            Repeater {
                model: 22
                Rectangle { width: 14; height: 50; y: -13; color: GroundTheme.ink; rotation: 45 }
            }
        }
    }
}
