// Control center NOTIFICATIONS tab = the notification-centre mock (ds-topbar-v2 ?state=notif): unread count,
// do-not-disturb, history grouped by app (badge, count, CLEAR), rows bright when unread / faded when read,
// CLEAR ALL. Opening the tab marks everything read.
import QtQuick

CCTab {
    id: root

    code: "NC-" + String(Notifs.records.length).padStart(2, "0") + " · " + Notifs.groups.length + " GROUPS"

    // read on leave, so the unread rows stay bright while you look at them
    Component.onDestruction: Notifs.markAllRead()

    CCHeader {
        title: "NOTIFICATIONS"
        sub: Notifs.groups.length + " SOURCES · SINCE LOGIN"
        count: String(Notifs.unread)
        countLabel: "UNREAD"
    }

    ToggleTile {
        x: 18
        width: parent.width - 36
        icon: Icons.dnd
        title: "DO NOT DISTURB"
        accent: Theme.orange
        on: Notifs.dnd
        status: Notifs.dnd ? "ON · CRITICAL ONLY" : "OFF"
        index: "DND"
        onClicked: Notifs.dnd = !Notifs.dnd
    }

    Item { width: 1; height: 6 }

    Repeater {
        model: Notifs.groups
        Column {
            id: grp
            required property var modelData
            width: parent.width

            // group head: badge · APP · count ———— CLEAR
            Item {
                width: parent.width
                height: 36
                Rectangle {
                    id: badge
                    x: 18
                    anchors.verticalCenter: parent.verticalCenter
                    width: 22
                    height: 22
                    color: AppColors.of(grp.modelData.app)
                    Text {
                        anchors.centerIn: parent
                        text: grp.modelData.app.charAt(0).toUpperCase()
                        color: Theme.plateInk
                        font.family: Theme.body
                        font.weight: Font.Bold
                        font.pixelSize: 11
                    }
                }
                Text {
                    id: appLabel
                    anchors.left: badge.right
                    anchors.leftMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    text: grp.modelData.app.toUpperCase()
                    color: Theme.ink2
                    font.family: Theme.mono
                    font.weight: Font.Bold
                    font.pixelSize: 10
                    font.letterSpacing: Theme.em(10, 0.2)
                }
                Text {
                    id: grpCount
                    anchors.left: appLabel.right
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: String(grp.modelData.items.length).padStart(2, "0")
                    color: Theme.faint
                    font.family: Theme.mono
                    font.pixelSize: 9
                }
                Rectangle {
                    anchors.left: grpCount.right
                    anchors.leftMargin: 10
                    anchors.right: clearText.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    height: 1
                    color: Qt.rgba(1, 1, 1, 0.08)
                }
                Text {
                    id: clearText
                    anchors.right: parent.right
                    anchors.rightMargin: 18
                    anchors.verticalCenter: parent.verticalCenter
                    text: "CLEAR"
                    color: clearArea.containsMouse ? Theme.ink : Theme.dim
                    font.family: Theme.mono
                    font.weight: Font.Bold
                    font.pixelSize: 9
                    font.letterSpacing: Theme.em(9, 0.16)
                    MouseArea {
                        id: clearArea
                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifs.clearGroup(grp.modelData.app)
                    }
                }
            }

            // items: summary · body (dim), age; unread bright, read faded
            Repeater {
                model: grp.modelData.items.slice(0, 5)
                Item {
                    id: it
                    required property var modelData
                    width: grp.width
                    height: 34
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 50
                        anchors.right: age.left
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        elide: Text.ElideRight
                        textFormat: Text.StyledText
                        text: it.modelData.n.summary.replace(/</g, "&lt;")
                            + (it.modelData.n.body ? " <font color='" + (it.modelData.read ? Theme.faint : Theme.dim) + "'>· "
                                + it.modelData.n.body.replace(/<[^>]+>/g, "").replace(/</g, "&lt;").replace(/\s*\n\s*/g, " ") + "</font>" : "")
                        color: it.modelData.read ? Theme.dim : Theme.ink
                        font.family: Theme.body
                        font.pixelSize: 13
                    }
                    Text {
                        id: age
                        anchors.right: parent.right
                        anchors.rightMargin: 18
                        anchors.verticalCenter: parent.verticalCenter
                        text: Notifs.ago(it.modelData.time)
                        color: "#43454c"
                        font.family: Theme.mono
                        font.pixelSize: 9
                        font.letterSpacing: Theme.em(9, 0.14)
                    }
                    Rectangle {
                        anchors.bottom: parent.bottom
                        x: 50
                        width: parent.width - 68
                        height: 1
                        color: Qt.rgba(1, 1, 1, 0.05)
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            it.modelData.n.actions.find(a => a.identifier === "default")?.invoke();
                            ControlCenter.close();
                        }
                    }
                }
            }
        }
    }

    Micro {
        x: 18
        topPadding: 10
        bottomPadding: 10
        visible: Notifs.records.length === 0
        text: "ALL CLEAR"
    }

    // CLEAR ALL (solid, right)
    Item {
        width: parent.width
        height: Notifs.records.length > 0 ? 52 : 0
        visible: Notifs.records.length > 0
        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            width: clearAllText.implicitWidth + 30
            height: 32
            color: clearAllArea.containsMouse ? Theme.yellow : Theme.ink
            Text {
                id: clearAllText
                anchors.centerIn: parent
                text: "CLEAR ALL"
                color: Theme.plateInk
                font.family: Theme.mono
                font.weight: Font.Bold
                font.pixelSize: 10
                font.letterSpacing: Theme.em(10, 0.2)
            }
            MouseArea {
                id: clearAllArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Notifs.clearAll()
            }
        }
    }
}
