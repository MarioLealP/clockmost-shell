// Control center CLIPBOARD tab = the clipboard mock (ds-topbar-v2 ?state=clip): type counts, search, pinned,
// recent history (Klipper), keyboard: type to search, Up/Down select, Enter copy + close, Ctrl+P pin, Del unpin.
import QtQuick

CCTab {
    id: root

    property string query: ""
    property int selected: 0
    readonly property var pinned: Clipboard.pins.filter(t => matches(t))
    readonly property var recent: Clipboard.history.filter(t => !Clipboard.isPinned(t) && matches(t)).slice(0, 8)
    readonly property var all: pinned.concat(recent)
    readonly property var counts: {
        const c = { TXT: 0, URL: 0, CMD: 0, HEX: 0, IMG: 0 };
        for (const t of Clipboard.history)
            c[Clipboard.kind(t)]++;
        return c;
    }

    function matches(t) {
        if (Clipboard.isImage(t))
            return query === "" || "image".startsWith(query.toLowerCase());
        return query === "" || t.toLowerCase().includes(query.toLowerCase());
    }
    function choose(i) {
        const t = all[i];
        if (t === undefined)
            return;
        Clipboard.copy(t, Clipboard.pasteOnPick);
        ControlCenter.close();
    }

    code: "CB-08"
    onQueryChanged: selected = 0

    Component.onCompleted: {
        Clipboard.watching = true;
        Clipboard.refresh();
        search.forceActiveFocus();
    }
    Component.onDestruction: Clipboard.watching = false
    // the tab stays loaded while the panel is closed: take the keyboard again on every open (Win+V, Enter)
    Connections {
        target: ControlCenter
        function onOpenChanged() {
            if (ControlCenter.open) {
                Clipboard.refresh();
                root.selected = 0;
                search.forceActiveFocus();
            }
        }
    }

    // header: CLIPBOARD + micro, type counts on the right
    Item {
        width: parent.width
        height: 64
        Column {
            x: 18
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            Text {
                text: "CLIPBOARD"
                color: Theme.ink
                font.family: Theme.mono
                font.weight: Font.Bold
                font.pixelSize: 18
                font.letterSpacing: Theme.em(18, 0.3)
            }
            Micro {
                text: "KLIPPER · " + Clipboard.history.length + " KEPT · " + Clipboard.pins.length + " PINNED"
            }
        }
        Grid {
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            columns: 2
            columnSpacing: 8
            rowSpacing: 1
            Repeater {
                model: ["TXT", "URL", "CMD", "HEX", "IMG"]
                Repeater {
                    required property string modelData
                    model: [modelData, String(root.counts[modelData]).padStart(2, "0")]
                    Text {
                        required property string modelData
                        required property int index
                        text: modelData
                        color: index === 0 ? "#43454c" : Theme.ink2
                        font.family: Theme.mono
                        font.weight: index === 0 ? Font.Normal : Font.Bold
                        font.pixelSize: 8
                        font.letterSpacing: Theme.em(8, 0.18)
                    }
                }
            }
        }
    }

    // search: ››› + input
    Rectangle {
        x: 18
        width: parent.width - 36
        height: 32
        color: "transparent"
        border.width: 1
        border.color: search.activeFocus ? Qt.rgba(1, 1, 1, 0.28) : Qt.rgba(1, 1, 1, 0.16)
        Text {
            id: prompt
            x: 12
            anchors.verticalCenter: parent.verticalCenter
            text: "›››"
            color: Theme.yellow
            font.family: Theme.mono
            font.weight: Font.Bold
            font.pixelSize: 12
        }
        TextInput {
            id: search
            anchors.left: prompt.right
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.ink
            font.family: Theme.mono
            font.pixelSize: 11
            font.letterSpacing: Theme.em(11, 0.1)
            selectionColor: Theme.yellow
            selectedTextColor: Theme.plateInk
            clip: true
            onTextChanged: root.query = text
            Keys.onUpPressed: root.selected = Math.max(0, root.selected - 1)
            Keys.onDownPressed: root.selected = Math.min(root.all.length - 1, root.selected + 1)
            Keys.onReturnPressed: root.choose(root.selected)
            Keys.onEnterPressed: root.choose(root.selected)
            Keys.onPressed: event => {
                const t = root.all[root.selected];
                if (event.key === Qt.Key_P && (event.modifiers & Qt.ControlModifier) && t !== undefined) {
                    Clipboard.togglePin(t);
                    event.accepted = true;
                } else if (event.key === Qt.Key_Delete && t !== undefined && Clipboard.isPinned(t)) {
                    Clipboard.togglePin(t);
                    event.accepted = true;
                }
            }
            Text {
                visible: !search.text
                anchors.verticalCenter: parent.verticalCenter
                text: "SEARCH CLIPBOARD"
                color: Theme.dim
                font: search.font
            }
        }
    }

    Item { width: 1; height: 12 }

    SectionLabel {
        x: 18
        width: parent.width - 36
        visible: root.pinned.length > 0
        text: "PINNED"
        note: String(root.pinned.length).padStart(2, "0")
    }
    Repeater {
        model: root.pinned
        ClipRow {
            required property string modelData
            required property int index
            text: modelData
            label: "P" + (index + 1)
            pinned: true
            selected: root.selected === index
            onClicked: root.choose(index)
            onPinClicked: Clipboard.togglePin(modelData)
        }
    }

    Item { width: 1; height: root.pinned.length > 0 ? 10 : 0 }
    SectionLabel {
        x: 18
        width: parent.width - 36
        text: "RECENT"
        note: String(Clipboard.history.length).padStart(2, "0")
    }
    Repeater {
        model: root.recent
        ClipRow {
            required property string modelData
            required property int index
            text: modelData
            label: String(index + 1).padStart(2, "0")
            ago: Clipboard.ago(modelData)
            selected: root.selected === root.pinned.length + index
            onClicked: root.choose(root.pinned.length + index)
            onPinClicked: Clipboard.togglePin(modelData)
        }
    }
    Micro {
        x: 18
        topPadding: 8
        visible: root.all.length === 0
        text: root.query ? "NO MATCH" : "CLIPBOARD IS EMPTY"
    }

    // key hints (the mock's footer row)
    Row {
        x: 18
        topPadding: 12
        bottomPadding: 10
        spacing: 14
        Repeater {
            model: [["⏎", "COPY"], ["↑↓", "MOVE"], ["CTRL P", "PIN"], ["DEL", "UNPIN"], ["ESC", "CLOSE"]]
            Row {
                required property var modelData
                spacing: 6
                Rectangle {
                    width: keyText.implicitWidth + 10
                    height: 18
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.22)
                    Text {
                        id: keyText
                        anchors.centerIn: parent
                        text: modelData[0]
                        color: Theme.ink2
                        font.family: Theme.mono
                        font.weight: Font.Bold
                        font.pixelSize: 8
                    }
                }
                Micro {
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData[1]
                    color: "#43454c"
                }
            }
        }
    }
}
