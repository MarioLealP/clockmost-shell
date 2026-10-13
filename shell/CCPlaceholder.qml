// A tab that isn't built yet: its title in the panel header style + a note.
import QtQuick

Column {
    id: root

    property string title: ""

    width: 432
    padding: 18
    spacing: 8

    Text {
        text: root.title
        color: Theme.ink
        font.family: Theme.mono
        font.weight: Font.Bold
        font.pixelSize: 18
        font.letterSpacing: Theme.em(18, 0.3)
    }
    Micro {
        text: "NEXT STEP · BUILT FROM ITS MOCK"
    }
    Item { width: 1; height: 120 }
}
