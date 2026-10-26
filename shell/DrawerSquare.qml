// One logo square of the drawer's deck (v2): the app's icon on a graphite cell, grey unless it's the featured one
// (orange frame, full colour); a monogram when the app ships no usable icon; its place in the list top-left, a pip per
// open window bottom-left. Solid colours only (cm-1jun).
import QtQuick
import QtQuick.Effects
import Quickshell

Rectangle {
    id: root

    property var entry: null
    property bool featured: false
    property int number: 0
    property int windows: 0
    property real fill: 0 // launching: orange rising from the bottom, under the logo
    signal clicked

    // curated marks win over the theme icon (the dock's firefox.svg)
    readonly property string logo: !entry ? "" : ({ "firefox": Qt.resolvedUrl("assets/logo-firefox.svg") })[(entry.id || "").toLowerCase()]
        ?? Quickshell.iconPath(entry.icon || "", true)
    // two letters: the first two words' initials, or the name's first two letters
    readonly property string monogram: {
        const w = (entry?.name ?? "").toUpperCase().split(/[^A-Z0-9]+/).filter(x => x);
        return w.length > 1 ? w[0][0] + w[1][0] : (w[0] ?? "").slice(0, 2);
    }

    color: area.containsMouse && !featured ? "#2a2a27" : "#222220"
    border.width: featured ? 2 : 1
    border.color: featured ? GroundTheme.acc : GroundTheme.lineSolid

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: parent.height * root.fill
        visible: root.fill > 0
        color: GroundTheme.acc
    }
    Image {
        id: icon
        visible: root.logo !== "" && status !== Image.Error
        anchors.centerIn: parent
        width: Math.round(parent.width * (root.featured ? 0.58 : 0.56))
        height: width
        source: root.logo
        sourceSize.width: 256
        sourceSize.height: 256
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        layer.enabled: !root.featured
        layer.effect: MultiEffect {
            saturation: -1
            brightness: -0.08
        }
    }
    Text {
        visible: !icon.visible
        anchors.centerIn: parent
        text: root.monogram
        color: root.featured ? GroundTheme.ink : GroundTheme.ink2
        font.family: GroundTheme.display
        font.weight: Font.Black
        font.variableAxes: { "wdth": 70, "wght": 900 }
        font.pixelSize: Math.round(parent.height * 0.42)
    }
    Text {
        visible: !root.featured && root.number > 0
        x: 6
        y: 4
        text: String(root.number).padStart(2, "0")
        color: GroundTheme.ink2
        font.family: GroundTheme.mono
        font.pixelSize: 9
        font.letterSpacing: 1
    }
    Row {
        x: 6
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6
        spacing: 3
        Repeater {
            model: Math.min(root.windows, 5)
            Rectangle { width: 4; height: 4; color: GroundTheme.acc }
        }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
