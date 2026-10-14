// .ce: one clipboard entry - index, type tag (TXT / URL / CMD / HEX + swatch), text, pin or age.
// Selected = the mock's yellow row with an arrow-cut right edge and a dot grid; tag flips to black/yellow.
import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property string text: ""
    property string label: "" // row number / P1 (not "index": delegates already have one)
    property bool selected: false
    property bool pinned: false
    property string ago: ""
    readonly property string kind: Clipboard.kind(text)
    readonly property color tagColor: ({ TXT: Theme.ink2, URL: "#5aa7ff", CMD: Theme.green, HEX: Theme.orange, IMG: Theme.magenta })[kind] ?? Theme.ink2
    signal clicked
    signal pinClicked

    width: parent ? parent.width : 0
    implicitHeight: Math.max(44, body.implicitHeight + 20)

    // selected: yellow slab with an arrow cut on the right (redrawn whenever the row resizes)
    Canvas {
        anchors.fill: parent
        visible: root.selected
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onVisibleChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.fillStyle = Theme.yellow;
            ctx.beginPath();
            ctx.moveTo(0, 0);
            ctx.lineTo(width - 10, 0);
            ctx.lineTo(width, height / 2);
            ctx.lineTo(width - 10, height);
            ctx.lineTo(0, height);
            ctx.closePath();
            ctx.fill();
        }
    }
    Rectangle {
        anchors.fill: parent
        visible: !root.selected && area.containsMouse
        color: Qt.rgba(1, 1, 1, 0.04)
    }
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: Qt.rgba(1, 1, 1, 0.05)
        visible: !root.selected
    }

    Text {
        x: 18
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: root.selected ? Theme.plateInk : "#43454c"
        font.family: Theme.mono
        font.pixelSize: 9
        font.letterSpacing: Theme.em(9, 0.1)
    }

    Rectangle {
        id: tag
        x: 54
        anchors.verticalCenter: parent.verticalCenter
        width: 28
        height: 14
        color: root.selected ? Theme.plateInk : root.tagColor
        Text {
            anchors.centerIn: parent
            text: root.kind
            color: root.selected ? Theme.yellow : Theme.plateInk
            font.family: Theme.mono
            font.weight: Font.Bold
            font.pixelSize: 8
            font.letterSpacing: Theme.em(8, 0.1)
        }
    }

    Row {
        id: body
        anchors.left: tag.right
        anchors.leftMargin: 22
        anchors.right: side.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8
        Rectangle {
            visible: root.kind === "HEX"
            anchors.verticalCenter: parent.verticalCenter
            width: 12
            height: 12
            color: root.kind === "HEX" ? root.text.trim() : "transparent"
        }
        // an image: thumbnail (up to 48px tall) + its size
        Image {
            id: thumb
            visible: root.kind === "IMG"
            anchors.verticalCenter: parent.verticalCenter
            source: visible ? "file://" + (Clipboard.images[root.text] ?? "") : ""
            height: visible ? Math.min(48, implicitHeight) : 0
            width: visible ? Math.min(parent.width - 80, implicitWidth * height / Math.max(1, implicitHeight)) : 0
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            mipmap: true // decoded at full size (8 rows at most): implicit size = the real size, for the label
        }
        Micro {
            visible: root.kind === "IMG"
            anchors.verticalCenter: parent.verticalCenter
            text: thumb.status === Image.Ready ? thumb.implicitWidth + "×" + thumb.implicitHeight : ""
            color: root.selected ? Theme.plateInk : Theme.faint
        }
        Text {
            visible: root.kind !== "IMG"
            width: parent.width - (root.kind === "HEX" ? 20 : 0)
            text: root.text.replace(/\s*\n\s*/g, " ⏎ ")
            maximumLineCount: 2
            wrapMode: Text.WrapAnywhere
            elide: Text.ElideRight
            color: root.selected ? Theme.plateInk : Theme.ink
            font.family: root.kind === "CMD" || root.kind === "HEX" ? Theme.mono : Theme.body
            font.weight: root.kind === "HEX" ? Font.Bold : Font.Normal
            font.pixelSize: 12
        }
    }

    Item {
        id: side
        anchors.right: parent.right
        anchors.rightMargin: 22
        anchors.verticalCenter: parent.verticalCenter
        width: 30
        height: 20
        Glyph {
            anchors.centerIn: parent
            visible: root.pinned
            size: 14
            path: "M9 3h6l-1 6 4 4H6l4-4z M12 13v8"
            color: root.selected ? Theme.plateInk : Theme.ink2
        }
        Micro {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.pinned
            text: root.ago
            color: root.selected ? Theme.plateInk : "#43454c"
        }
        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onClicked: root.pinClicked()
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.rightMargin: 52
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
