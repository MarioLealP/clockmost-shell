// .pop: one notification popup (ds-topbar-v2 ?state=pop): app-colour block with its initial + dot grid,
// APP · time · ×, title, one-line body, optional progress / image, action buttons (first one solid).
// Click the body = the default action. Times out unless critical (or the app asked for "never").
import QtQuick
import QtQuick.Effects
import Quickshell.Services.Notifications

Item {
    id: root

    required property var rec
    readonly property var n: rec.n
    readonly property color appColor: AppColors.of(n.appName)
    readonly property var buttons: n.actions.filter(a => a.identifier !== "default")
    readonly property var defaultAction: n.actions.find(a => a.identifier === "default") ?? null
    readonly property real progress: n.hints && n.hints.value !== undefined ? Number(n.hints.value) / 100 : -1
    property bool shown: false

    width: 400
    implicitHeight: Math.max(96, body.implicitHeight + 24)
    opacity: shown ? 1 : 0
    transform: Translate { x: root.shown ? 0 : 40; Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } } }
    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    Component.onCompleted: shown = true

    // leave the way it came (slide right + fade), then drop out of the stack
    function close() {
        shown = false;
        leave.start();
    }
    Timer {
        id: leave
        interval: 220
        onTriggered: Notifs.hidePopup(root.rec)
    }

    Timer {
        running: root.n.urgency !== NotificationUrgency.Critical && root.n.expireTimeout !== 0 && !hover.hovered
        interval: root.n.expireTimeout > 0 ? root.n.expireTimeout : 6000
        onTriggered: root.close()
    }
    HoverHandler {
        id: hover
    }

    RectangularShadow {
        anchors.fill: card
        offset.y: 18
        blur: 40
        color: Qt.rgba(0, 0, 0, 0.5)
    }
    Rectangle {
        id: card
        anchors.fill: parent
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.12)
        gradient: Gradient {
            GradientStop { position: 0; color: Qt.rgba(30 / 255, 31 / 255, 36 / 255, 0.96) }
            GradientStop { position: 1; color: Qt.rgba(16 / 255, 17 / 255, 20 / 255, 0.95) }
        }
        Hatch {
            anchors.fill: parent
            color: Qt.rgba(1, 1, 1, 0.05)
        }
        // the hatch fades out toward the text
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.rgba(16 / 255, 17 / 255, 20 / 255, 0.25) }
                GradientStop { position: 0.45; color: Qt.rgba(16 / 255, 17 / 255, 20 / 255, 0.92) }
            }
        }
    }

    // app block
    Rectangle {
        id: block
        width: 56
        height: parent.height
        color: root.appColor
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: 14
            text: (root.n.appName || "?").charAt(0).toUpperCase()
            color: Theme.plateInk
            font.family: Theme.body
            font.weight: Font.Bold
            font.variableAxes: { "wght": 700 }
            font.pixelSize: 18
        }
        DotGrid {
            x: 8
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 8
            width: 18
            height: 12
            pitch: 4
            color: Qt.rgba(0.067, 0.067, 0.067, 0.4)
        }
    }

    Column {
        id: body
        anchors.left: block.right
        anchors.leftMargin: 14
        anchors.right: parent.right
        anchors.rightMargin: 14
        y: 12
        spacing: 3

        Row {
            width: parent.width
            spacing: 8
            Text {
                text: (root.n.appName || "").toUpperCase()
                color: Theme.ink2
                font.family: Theme.mono
                font.weight: Font.Bold
                font.pixelSize: 10
                font.letterSpacing: Theme.em(10, 0.2)
            }
            Micro {
                anchors.verticalCenter: parent.verticalCenter
                text: Notifs.ago(root.rec.time)
            }
        }
        Item { width: 1; height: 4 }
        Text {
            width: parent.width - (thumb.visible ? thumb.width + 10 : 0)
            elide: Text.ElideRight
            text: root.n.summary
            color: Theme.ink
            font.family: Theme.body
            font.weight: Font.DemiBold
            font.variableAxes: { "wght": 600 }
            font.pixelSize: 14
        }
        Text {
            width: parent.width - (thumb.visible ? thumb.width + 10 : 0)
            visible: text !== ""
            elide: Text.ElideRight
            text: root.n.body.replace(/<[^>]+>/g, "").replace(/\s*\n\s*/g, " ")
            color: Theme.ink2
            font.family: Theme.body
            font.pixelSize: 13
        }
        // progress (hint "value", 0..100)
        Rectangle {
            visible: root.progress >= 0
            width: parent.width
            height: 3
            color: Qt.rgba(125 / 255, 219 / 255, 87 / 255, 0.2)
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, root.progress))
                height: parent.height
                color: Theme.green
            }
        }
        Row {
            visible: root.buttons.length > 0
            topPadding: 7
            spacing: 6
            Repeater {
                model: root.buttons
                Rectangle {
                    id: btn
                    required property var modelData
                    required property int index
                    width: btnText.implicitWidth + 20
                    height: 26
                    color: index === 0 ? Theme.ink : btnArea.containsMouse ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
                    border.width: 1
                    border.color: index === 0 ? Theme.ink : Qt.rgba(1, 1, 1, 0.18)
                    Text {
                        id: btnText
                        anchors.centerIn: parent
                        text: btn.modelData.text.toUpperCase()
                        color: btn.index === 0 ? Theme.plateInk : Theme.ink2
                        font.family: Theme.mono
                        font.weight: Font.Bold
                        font.pixelSize: 10
                        font.letterSpacing: Theme.em(10, 0.16)
                    }
                    MouseArea {
                        id: btnArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: btn.modelData.invoke()
                    }
                }
            }
        }
    }

    // image thumbnail (screenshots etc), notched corner
    Image {
        id: thumb
        visible: status === Image.Ready
        anchors.right: parent.right
        anchors.rightMargin: 14
        y: 36
        width: 96
        height: 54
        source: root.n.image || ""
        fillMode: Image.PreserveAspectCrop
    }

    // body click = default action; then the popup goes
    MouseArea {
        anchors.fill: parent
        anchors.leftMargin: 56
        z: -1
        cursorShape: root.defaultAction ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            root.defaultAction?.invoke();
            root.close();
        }
    }

    // ×
    Item {
        anchors.right: parent.right
        anchors.rightMargin: 8
        y: 8
        width: 20
        height: 20
        Glyph {
            anchors.centerIn: parent
            size: 12
            stroke: 3
            path: "M5 5l5 5M14 14l5 5M19 5l-5 5M10 14l-5 5"
            color: xArea.containsMouse ? Theme.ink : Theme.dim
        }
        MouseArea {
            id: xArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.close()
        }
    }

    // corner brackets (10px)
    Repeater {
        model: [{ x: -2, y: -2, r: 0 }, { x: root.width - 8, y: root.height - 8, r: 180 }]
        Item {
            required property var modelData
            x: modelData.x
            y: modelData.y
            width: 10
            height: 10
            rotation: modelData.r
            Rectangle { width: 10; height: 2; color: Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.5) }
            Rectangle { width: 2; height: 10; color: Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.5) }
        }
    }
}
