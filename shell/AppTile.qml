// One drawer app tile = ds-app-drawer's .tile, rule by rule:
//   .tile        120px square, 6px corners, inset shadows, rgba(70,74,82,.5)            -> TileFrame
//   .topo        ds-topo-card.svg, object-fit cover, opacity .5
//   .logo        left 50% / top 27% / 46% square - the app's own icon (curated mark where we have one)
//   .letter      700 29px body, centred - only when the app ships no icon (the mock's letters were placeholders)
//   .name        top 78%, 600 18px mono, .12em
//   .code        top 6%, 10px mono, .22em, #6c6f76   ("v128 · BRW" / "· COM")
//   .bar         bottom 3px, the app's colour
// Selected (keyboard) = yellow outline - not in the mock, needed for arrow-key navigation.
import QtQuick
import Quickshell
import QtQuick.Effects

TileFrame {
    id: root

    required property var entry
    property bool selected: false
    // curated marks win over the theme icon (the mock's firefox.svg)
    readonly property var logos: ({ "firefox": Qt.resolvedUrl("assets/logo-firefox.svg") })
    readonly property string logo: logos[(entry.id || "").toLowerCase()] ?? Quickshell.iconPath(entry.icon || "", true)
    signal activated

    fill: area.containsMouse ? Qt.rgba(84 / 255, 88 / 255, 98 / 255, 0.6) : Qt.rgba(70 / 255, 74 / 255, 82 / 255, 0.5)

    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl("assets/topo-card.svg")
        // the asset's viewBox is pre-cropped to the centred square CSS object-fit: cover shows (QtSvg ignores
        // preserveAspectRatio slice); rendered at tile size so the 1px contour lines don't thin out when scaled
        sourceSize.width: width
        sourceSize.height: height
        smooth: true
        opacity: 0.5
    }

    Image {
        id: icon
        visible: root.logo !== ""
        x: (parent.width - width) / 2
        y: parent.height * 0.27
        width: parent.width * 0.46
        height: width
        source: root.logo
        sourceSize.width: 128
        sourceSize.height: 128
        smooth: true
        // greyscale at rest so app colours don't fight the HUD palette; colour eases back on hover / selection
        property real tint: area.containsMouse || root.selected ? 1 : 0
        Behavior on tint { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        layer.enabled: true
        layer.effect: MultiEffect {
            saturation: -1 + icon.tint
        }
    }
    Text {
        visible: root.logo === ""
        anchors.centerIn: parent
        text: root.entry.name.charAt(0).toUpperCase()
        color: "#e8e9ec"
        font.family: Theme.body
        font.weight: Font.Bold
        font.pixelSize: 29
    }

    Text {
        y: parent.height * 0.78
        width: parent.width - 8
        x: 4
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        text: root.entry.name
        color: "#e8e9ec"
        font.family: Theme.mono
        font.weight: Font.DemiBold
        font.pixelSize: 18
        font.letterSpacing: Theme.em(18, 0.12)
    }

    Text {
        y: parent.height * 0.06
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        textFormat: Text.StyledText
        text: "· " + Apps.code(root.entry) + (DockApps.isPinned(root.entry.id) ? " · <font color='" + Theme.yellow + "'>PIN</font>" : "")
        color: "#6c6f76"
        font.family: Theme.mono
        font.pixelSize: 10
        font.letterSpacing: Theme.em(10, 0.22)
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 3
        color: AppColors.of(root.entry.name)
    }

    Rectangle {
        visible: root.selected
        anchors.fill: parent
        radius: 6
        color: "transparent"
        border.width: 2
        border.color: Theme.yellow
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        // right click = pin / unpin in the dock
        onClicked: mouse => mouse.button === Qt.RightButton ? DockApps.togglePin(root.entry.id) : root.activated()
    }
}
