// The one accent line: a 6px bar, rotated 28deg off vertical, top-left anchored (runs down to the left).
import QtQuick

Rectangle {
    width: 6
    height: 2200
    color: GroundTheme.acc
    rotation: 28
    transformOrigin: Item.TopLeft
}
