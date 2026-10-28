// The clockmost startup splash (KSplash, between the login and the desktop): the ground's graphite and nothing else,
// so the login's strokes leave onto the same colour the desktop then builds on (desktop-environment-v2 stage 5:
// "first the grey background, then the dots, then load stuff in"). KSplash sets `stage`; Plasma closes it when ready.
import QtQuick

Rectangle {
    property int stage
    color: "#1a1a18"
}
