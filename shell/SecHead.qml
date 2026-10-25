// Section header: ← BACK, the section name, a meta chip on the right. BACK (or clicking the row again) closes.
import QtQuick

Item {
    id: root

    property string title
    property string meta
    signal back()

    width: parent?.width ?? 560
    height: 64

    Rectangle {
        id: backBtn
        anchors.verticalCenter: parent.verticalCenter
        width: bt.implicitWidth + 20
        height: 26
        color: ma.containsMouse ? GroundTheme.acc : GroundTheme.ink
        Text { id: bt; anchors.centerIn: parent; text: "← BACK"; color: GroundTheme.bg; font.family: GroundTheme.mono; font.pixelSize: 11; font.letterSpacing: 2 }
        MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.back() }
    }
    Text {
        x: backBtn.width + 14
        anchors.verticalCenter: parent.verticalCenter
        text: root.title
        color: GroundTheme.ink
        font.family: GroundTheme.display
        font.pixelSize: 44
        font.weight: Font.Black
        font.variableAxes: { "wdth": 70 }
    }
    Rectangle {
        visible: root.meta !== ""
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: mt.implicitWidth + 16
        height: 22
        color: GroundTheme.acc
        Text { id: mt; anchors.centerIn: parent; text: root.meta; color: GroundTheme.accInk; font.family: GroundTheme.mono; font.pixelSize: 11; font.letterSpacing: 2 }
    }
    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 2; color: GroundTheme.ink }
}
