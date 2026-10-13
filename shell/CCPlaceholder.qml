// A tab that isn't built yet: its title in the panel header style + a note.
import QtQuick

CCTab {
    id: root

    property string title: ""

    code: "CC-" + title.slice(0, 2)

    Item { width: 1; height: 18 }
    Text {
        x: 18
        text: root.title
        color: Theme.ink
        font.family: Theme.mono
        font.weight: Font.Bold
        font.pixelSize: 18
        font.letterSpacing: Theme.em(18, 0.3)
    }
    Micro {
        x: 18
        topPadding: 6
        text: "NEXT STEP · BUILT FROM ITS MOCK"
    }
}
