// CSS `box-shadow: inset 0 <offsetY>px <blur>px <color>` for a rounded box. Qt has no inset shadow, so: a thick
// frame whose inner edge is the box edge (shifted by offsetY), blurred, and clipped to the box's rounded shape -
// the blurred inner edge bleeds inward exactly like the CSS shadow. Put it above the background, below content.
import QtQuick
import QtQuick.Effects

Item {
    id: root

    property real radius: 6
    property real offsetY: 2
    property real blur: 10
    property color color: Qt.rgba(0, 0, 0, 0.6)
    readonly property real frame: blur * 2 + 4

    anchors.fill: parent
    layer.enabled: true
    layer.effect: MultiEffect {
        maskEnabled: true
        maskSource: shape
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }

    Rectangle {
        x: -root.frame
        y: -root.frame + root.offsetY
        width: root.width + 2 * root.frame
        height: root.height + 2 * root.frame
        radius: root.radius + root.frame
        color: "transparent"
        border.width: root.frame
        border.color: root.color
        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 1.0
            blurMax: Math.round(root.blur * 1.6) // CSS blur radius ~ 2 sigma; MultiEffect's blurMax ~ the kernel reach
        }
    }

    Item {
        id: shape
        anchors.fill: parent
        visible: false
        layer.enabled: true
        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: "white"
        }
    }
}
