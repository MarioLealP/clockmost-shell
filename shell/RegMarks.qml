// Registration corners at the four corners of the ground (top ones clear the bar). Their 2 px lines sit centred on
// dots of the 24 px grid (DotGrid's centring), whatever the screen size.
import QtQuick

Item {
    id: root

    property int inset: 40
    property int topY: 84
    property int size: 28
    property int pitch: 24

    // the nearest dot to v along a side of length len (DotGrid's centred grid)
    function snap(v, len) {
        const off = (len % pitch) / 2 + pitch / 2;
        return off + Math.round((v - off) / pitch) * pitch;
    }
    readonly property real markL: snap(inset, width) - 1
    readonly property real markR: snap(width - inset, width) + 1 - size
    readonly property real markT: snap(topY, height) - 1
    readonly property real markB: snap(height - inset, height) + 1 - size

    component Corner: Item {
        property bool flipX: false
        property bool flipY: false
        width: root.size
        height: root.size
        transform: Scale { origin.x: root.size / 2; origin.y: root.size / 2; xScale: flipX ? -1 : 1; yScale: flipY ? -1 : 1 }
        Rectangle { width: parent.width; height: 2; color: GroundTheme.ink }
        Rectangle { width: 2; height: parent.height; color: GroundTheme.ink }
    }

    Corner { x: root.markL; y: root.markT }
    Corner { x: root.markR; y: root.markT; flipX: true }
    Corner { x: root.markL; y: root.markB; flipY: true }
    Corner { x: root.markR; y: root.markB; flipX: true; flipY: true }
}
