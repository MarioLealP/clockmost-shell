// ds-dock-v2 .drawer: 56px olive slab - linear-gradient(180deg, rgba(255,250,0,.30), rgba(255,250,0,.55)),
// 1px rgba(255,250,0,.45) border, #fffbb0 2x2 grid glyph (22px, stroke 2.4); ::after = 6px dot grid
// rgba(255,250,0,.35) masked by linear-gradient(135deg, transparent 45%, #000); "WIN" 700 7px mono .14em #d8d36a.
import QtQuick

Item {
    id: root

    width: 56
    height: 56

    // v2: an outlined dark tile on the bone plate with a magnifier - the drawer is search-first
    Rectangle {
        anchors.fill: parent
        color: area.containsMouse ? Qt.rgba(0, 0, 0, 0.08) : "transparent"
        border.width: 1.5
        border.color: GroundTheme.bg
    }

    Canvas {
        anchors.centerIn: parent
        width: 24
        height: 24
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.strokeStyle = GroundTheme.bg;
            ctx.lineWidth = 2;
            ctx.lineCap = "round";
            ctx.beginPath();
            ctx.arc(10.5, 10.5, 6.5, 0, 2 * Math.PI);
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(15.5, 15.5);
            ctx.lineTo(21, 21);
            ctx.stroke();
        }
    }

    Text {
        x: 4
        y: 3
        text: "SEARCH"
        color: Qt.rgba(0.1, 0.1, 0.09, 0.6)
        font.family: GroundTheme.mono
        font.pixelSize: 7
        font.letterSpacing: 1
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Drawer.toggle()
    }
}
