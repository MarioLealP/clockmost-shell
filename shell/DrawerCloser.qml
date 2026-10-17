// Closes the app drawer on any press inside a bar / dock window, then lets the press through to what's under it
// (accepted = false). Put it last in the window so it sits on top; inert while the drawer is shut.
import QtQuick

MouseArea {
    anchors.fill: parent
    z: 10000
    enabled: Drawer.open
    acceptedButtons: Qt.AllButtons
    onPressed: mouse => {
        Drawer.close();
        mouse.accepted = false;
    }
}
