// .micro: 9px mono, .18em tracking, faint, uppercase.
import QtQuick

Text {
    color: Theme.faint
    font.family: Theme.mono
    font.pixelSize: 9
    font.letterSpacing: Theme.em(9, 0.18)
    font.capitalization: Font.AllUppercase
}
