// The clockmost startup splash (KSplash, between the login and the desktop): the ground's graphite and nothing else
// (brightening up from the login's black),
// so the login's strokes leave onto the same colour the desktop then builds on (desktop-environment-v2 stage 5:
// "first the grey background, then the dots, then load stuff in"). KSplash sets `stage`; Plasma closes it when ready.
import QtQuick

Rectangle {
    id: root
    property int stage
    // up from black: the login ends on black for the handover between the login's KWin and the session's
    color: "#000000"
    ColorAnimation on color { to: "#1a1a18"; duration: 420; easing.type: Easing.OutQuad }
}
