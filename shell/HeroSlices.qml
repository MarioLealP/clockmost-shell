// Four staggered windows onto one continuous picture (the NEONMOON poster), outlined, with hazard bars + brackets.
import QtQuick

Item {
    id: root

    property url source: GroundTheme.art
    property int gap: 26
    // [top, bottom] of each window; the picture is drawn once across the full width so it stays continuous
    property var spans: [[0, 900], [110, 1180], [0, 930], [90, 1060]]
    readonly property real paneW: (width - 3 * gap) / 4

    width: 1120
    height: 1180

    component Hazard: Rectangle {
        property color stripe: GroundTheme.ink
        height: 30
        color: "transparent"
        clip: true
        Row {
            x: -30
            spacing: 14
            Repeater {
                model: Math.ceil(parent.parent.width / 28) + 3
                Rectangle { width: 14; height: 60; y: -15; color: stripe; rotation: 45 }
            }
        }
    }

    Repeater {
        model: root.spans
        Item {
            required property var modelData
            required property int index
            x: index * (root.paneW + root.gap)
            y: modelData[0]
            width: root.paneW
            height: modelData[1] - modelData[0]

            Rectangle {
                anchors.fill: parent
                anchors.margins: -6
                color: "transparent"
                border.width: 2
                border.color: GroundTheme.ink
            }
            Item {
                anchors.fill: parent
                clip: true
                Image {
                    x: -parent.parent.x
                    y: -parent.parent.y - 40
                    width: root.width
                    height: root.width * (sourceSize.height / Math.max(1, sourceSize.width))
                    source: root.source
                    fillMode: Image.Stretch
                    smooth: true
                    mipmap: true
                    asynchronous: true
                }
            }
        }
    }

    Hazard { x: -40; y: -70; width: 300 }
    Hazard { x: root.width - 340; y: root.height + 10; width: 380; stripe: GroundTheme.acc }

    Rectangle { // left bracket
        x: -70; y: 120; width: 40; height: 560
        color: "transparent"
        Rectangle { width: 2; height: parent.height; color: GroundTheme.ink }
        Rectangle { width: parent.width; height: 2; color: GroundTheme.ink }
        Rectangle { y: parent.height - 2; width: parent.width; height: 2; color: GroundTheme.ink }
    }
    Rectangle { // top-right bracket
        x: root.width - 280; y: -70; width: 300; height: 260 // right line 20 px outside the last pane, clear of the Felt column
        color: "transparent"
        Rectangle { width: parent.width; height: 2; color: GroundTheme.ink }
        Rectangle { x: parent.width - 2; width: 2; height: parent.height; color: GroundTheme.ink }
    }
}
