// One window in the dock's hover panel - in the dock's language, not the drawer's tiles (Mario: the reused drawer
// cards looked off): square corners, 1px rgba(255,255,255,.10) frame on rgba(30,32,37,.7) like the dock tiles,
// the live preview edge to edge, one caption strip (icon, title, state tag), an app-colour underline.
// Active window = 2px yellow frame + yellow underline (the dock's focus language).
//   preview   220x124 on #0d0e10 - a live KWin screencast of the window (zkde_screencast via KDE's taskmanager +
//             pipewire QML, like Plasma's taskbar; needs install/org.clockmost.shell.desktop)
//   caption   28px: 14px icon, title 10px mono .08em #c9ccd3; tag 700 8px mono .14em -
//             ACTIVE = #111 on yellow, MINIMIZED = orange on #0b0b0c with a 1px rgba(255,255,255,.12) border
//   underline 2px, the app colour
import QtQuick
import Quickshell
import org.kde.taskmanager as TM
import org.kde.pipewire as PW

Item {
    id: root

    required property var win
    property color c: AppColors.of(win.app)
    property string icon: ""
    readonly property bool sel: win.active
    signal activated
    signal closeRequested

    width: 220
    height: 124 + 28 + 2

    Rectangle {
        anchors.fill: parent
        color: area.containsMouse ? Qt.rgba(44 / 255, 46 / 255, 52 / 255, 0.85) : Qt.rgba(30 / 255, 32 / 255, 37 / 255, 0.7)
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    Rectangle {
        id: pv
        width: parent.width
        height: 124
        color: "#0d0e10"
        clip: true

        PW.PipeWireSourceItem {
            id: stream
            anchors.centerIn: parent
            // fit the window's aspect inside the frame
            readonly property real aspect: streamSize.height > 0 ? streamSize.width / streamSize.height : root.win.w / Math.max(1, root.win.h)
            width: Math.min(parent.width, parent.height * aspect)
            height: width / aspect
            nodeId: request.nodeId
            visible: nodeId > 0
            opacity: root.win.minimized && !area.containsMouse ? 0.6 : 1
            TM.ScreencastingRequest {
                id: request
                uuid: root.win.id
            }
        }
        // no stream (not granted / starting): the app icon on the dark ground
        Image {
            visible: !stream.visible
            anchors.centerIn: parent
            width: 36
            height: 36
            source: root.icon
            sourceSize.width: 72
            sourceSize.height: 72
            opacity: 0.5
        }
    }
    // hairline between preview and caption
    Rectangle {
        y: 124
        width: parent.width
        height: 1
        color: Qt.rgba(1, 1, 1, 0.08)
    }

    Item {
        y: 124
        width: parent.width
        height: 28

        Image {
            id: ico
            x: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 14
            height: 14
            source: root.icon
            sourceSize.width: 28
            sourceSize.height: 28
        }
        Text {
            anchors.left: ico.right
            anchors.leftMargin: 7
            anchors.right: tag.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            text: root.win.title.toUpperCase()
            color: Theme.ink2
            font.family: Theme.mono
            font.pixelSize: 10
            font.letterSpacing: Theme.em(10, 0.08)
        }
        Rectangle {
            id: tag
            visible: root.sel || root.win.minimized
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: visible ? tagText.implicitWidth + 10 : 0
            height: 14
            color: root.sel ? Theme.yellow : "#0b0b0c"
            border.width: root.sel ? 0 : 1
            border.color: Qt.rgba(1, 1, 1, 0.12)
            Text {
                id: tagText
                anchors.centerIn: parent
                text: root.sel ? "ACTIVE" : "MINIMIZED"
                color: root.sel ? "#111111" : Theme.orange
                font.family: Theme.mono
                font.weight: Font.Bold
                font.pixelSize: 8
                font.letterSpacing: Theme.em(8, 0.14)
            }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 2
        color: root.sel ? Theme.yellow : root.c
    }
    // frame: 1px rgba(255,255,255,.10), hover brighter, active 2px yellow
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: root.sel ? 2 : 1
        border.color: root.sel ? Theme.yellow : area.containsMouse ? Qt.rgba(241 / 255, 241 / 255, 244 / 255, 0.35) : Qt.rgba(1, 1, 1, 0.10)
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        // left = focus this window, middle = close it (Mario)
        onClicked: mouse => mouse.button === Qt.MiddleButton ? root.closeRequested() : root.activated()
    }
}
