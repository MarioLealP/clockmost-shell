// The mock's .tile box (ds-app-drawer): 6px corners, overflow hidden, background, then
//   box-shadow: inset 0 2px 10px rgba(0,0,0,.6), inset 0 0 0 1px rgba(0,0,0,.35);
// .tile.empty adds border 1px rgba(255,255,255,.18) and the 9px dot grid. Content (default) sits above the shadows,
// and everything - including the underbar - is clipped to the rounded corners.
import QtQuick
import QtQuick.Effects

Item {
    id: root

    property bool empty: false
    property color fill: empty ? Qt.rgba(70 / 255, 74 / 255, 82 / 255, 0.3) : Qt.rgba(70 / 255, 74 / 255, 82 / 255, 0.5)
    property real radius: 6
    default property alias content: inner.data

    width: 120
    height: 120
    layer.enabled: true
    layer.effect: MultiEffect {
        maskEnabled: true
        maskSource: shape
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: root.fill
        Behavior on color { ColorAnimation { duration: 120 } }
    }
    // .tile.empty: radial-gradient(rgba(255,255,255,.16) 1px, transparent 1.4px) 0 0 / 9px 9px
    DotGrid {
        visible: root.empty
        anchors.fill: parent
        pitch: 9
        radius: 1.2
        color: Qt.rgba(1, 1, 1, 0.16)
    }

    // inset 0 2px 10px rgba(0,0,0,.6)
    InsetShadow {
        radius: root.radius
        offsetY: 2
        blur: 10
        color: Qt.rgba(0, 0, 0, 0.6)
    }

    Item {
        id: inner
        anchors.fill: parent
    }

    // .tile.empty border 1px rgba(255,255,255,.18) (outer edge), then inset 0 0 0 1px rgba(0,0,0,.35) inside it
    Rectangle {
        visible: root.empty
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.18)
    }
    Rectangle {
        anchors.fill: parent
        anchors.margins: root.empty ? 1 : 0
        radius: root.radius - (root.empty ? 1 : 0)
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(0, 0, 0, 0.35)
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
