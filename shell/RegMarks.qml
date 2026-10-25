// Registration corners at the four corners of the ground (top ones clear the bar).
import QtQuick

Item {
    id: root

    property int inset: 40
    property int topY: 84
    property int size: 28

    component Corner: Item {
        property bool flipX: false
        property bool flipY: false
        width: root.size
        height: root.size
        transform: Scale { origin.x: root.size / 2; origin.y: root.size / 2; xScale: flipX ? -1 : 1; yScale: flipY ? -1 : 1 }
        Rectangle { width: parent.width; height: 2; color: GroundTheme.ink }
        Rectangle { width: 2; height: parent.height; color: GroundTheme.ink }
    }

    Corner { x: root.inset; y: root.topY }
    Corner { x: root.width - root.inset - root.size; y: root.topY; flipX: true }
    Corner { x: root.inset; y: root.height - root.inset - root.size; flipY: true }
    Corner { x: root.width - root.inset - root.size; y: root.height - root.inset - root.size; flipX: true; flipY: true }
}
