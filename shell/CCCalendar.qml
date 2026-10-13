// Control center CALENDAR tab = the calendar mock (ds-topbar-v2 ?state=cal): month header with ‹ ›, ISO week
// column, Monday-first grid, today boxed in yellow, an upcoming list (no calendar source linked yet), ISO footer.
import QtQuick
import Quickshell

CCTab {
    id: root

    property int monthOffset: 0 // 0 = this month
    readonly property date now: clock.date
    readonly property date first: new Date(now.getFullYear(), now.getMonth() + monthOffset, 1)
    // grid starts on the Monday on/before the 1st (ISO weeks, Portugal)
    readonly property date gridStart: {
        const d = new Date(first);
        d.setDate(d.getDate() - ((d.getDay() + 6) % 7));
        return d;
    }
    readonly property int weeks: {
        const last = new Date(first.getFullYear(), first.getMonth() + 1, 0);
        const days = Math.round((last - gridStart) / 86400000) + 1;
        return Math.ceil(days / 7);
    }

    function isoWeek(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        const day = t.getUTCDay() || 7;
        t.setUTCDate(t.getUTCDate() + 4 - day);
        const yearStart = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
        return Math.ceil(((t - yearStart) / 86400000 + 1) / 7);
    }
    function dayOfYear(d) {
        return Math.round((new Date(d.getFullYear(), d.getMonth(), d.getDate()) - new Date(d.getFullYear(), 0, 0)) / 86400000);
    }
    function sameDay(a, b) {
        return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
    }
    function utcOffset(d) {
        const m = -d.getTimezoneOffset();
        return (m < 0 ? "-" : "+") + Math.floor(Math.abs(m) / 60) + (Math.abs(m) % 60 ? ":" + String(Math.abs(m) % 60).padStart(2, "0") : "");
    }

    // footer: ISO week · day of year · UTC offset
    code: "ISO W" + String(isoWeek(now)).padStart(2, "0") + " · DAY " + dayOfYear(now) + "/"
        + dayOfYear(new Date(now.getFullYear(), 11, 31)) + " · UTC" + utcOffset(now)

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // month header: OCTOBER 2026 (year dim, regular) + ‹ ›
    Item {
        width: parent.width
        height: 58
        Row {
            x: 18
            anchors.verticalCenter: parent.verticalCenter
            spacing: 12
            Text {
                text: Qt.formatDate(root.first, "MMMM").toUpperCase()
                color: Theme.ink
                font.family: Theme.mono
                font.weight: Font.Bold
                font.pixelSize: 16
                font.letterSpacing: Theme.em(16, 0.28)
            }
            Text {
                text: root.first.getFullYear()
                color: Theme.dim
                font.family: Theme.mono
                font.pixelSize: 16
                font.letterSpacing: Theme.em(16, 0.28)
            }
        }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6
            Repeater {
                model: [{ t: "‹", d: -1 }, { t: "·", d: 0 }, { t: "›", d: 1 }]
                Rectangle {
                    id: nav
                    required property var modelData
                    width: 26
                    height: 26
                    color: navArea.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : "transparent"
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.16)
                    Text {
                        anchors.centerIn: parent
                        text: nav.modelData.t
                        color: nav.modelData.d === 0 && root.monthOffset !== 0 ? Theme.yellow : Theme.ink2
                        font.family: Theme.mono
                        font.pixelSize: 12
                    }
                    MouseArea {
                        id: navArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.monthOffset = nav.modelData.d === 0 ? 0 : root.monthOffset + nav.modelData.d
                    }
                }
            }
        }
    }

    // grid: 34px week column + 7 days
    Item {
        id: grid
        x: 18
        width: parent.width - 36
        height: 30 + root.weeks * 38
        readonly property real col: (width - 34) / 7

        // header row
        Text {
            y: 6
            text: "WK"
            color: "#43454c"
            font.family: Theme.mono
            font.weight: Font.Bold
            font.pixelSize: 9
            font.letterSpacing: Theme.em(9, 0.18)
        }
        Repeater {
            model: ["MO", "TU", "WE", "TH", "FR", "SA", "SU"]
            Text {
                required property string modelData
                required property int index
                x: 34 + index * grid.col
                y: 6
                width: grid.col
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: Theme.dim
                font.family: Theme.mono
                font.weight: Font.Bold
                font.pixelSize: 9
                font.letterSpacing: Theme.em(9, 0.18)
            }
        }
        Rectangle { y: 24; width: parent.width; height: 1; color: Qt.rgba(1, 1, 1, 0.08) }

        // week rows
        Repeater {
            model: root.weeks
            Item {
                id: week
                required property int index
                readonly property date monday: new Date(root.gridStart.getFullYear(), root.gridStart.getMonth(), root.gridStart.getDate() + index * 7)
                readonly property bool thisWeek: root.isoWeek(monday) === root.isoWeek(root.now) && Math.abs(monday - root.now) < 7 * 86400000
                y: 30 + index * 38
                width: grid.width
                height: 36

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "W" + String(root.isoWeek(week.monday)).padStart(2, "0")
                    color: week.thisWeek ? Theme.yellow : "#43454c"
                    font.family: Theme.mono
                    font.weight: week.thisWeek ? Font.Bold : Font.Normal
                    font.pixelSize: 9
                    font.letterSpacing: Theme.em(9, 0.1)
                }
                Repeater {
                    model: 7
                    Item {
                        id: cell
                        required property int index
                        readonly property date day: new Date(week.monday.getFullYear(), week.monday.getMonth(), week.monday.getDate() + index)
                        readonly property bool inMonth: day.getMonth() === root.first.getMonth()
                        readonly property bool today: root.sameDay(day, root.now)
                        x: 34 + index * grid.col
                        width: grid.col
                        height: 36

                        // today: yellow outline inset 3px + a 6px square top-left
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 3
                            visible: cell.today
                            color: "transparent"
                            border.width: 1
                            border.color: Theme.yellow
                        }
                        Rectangle {
                            visible: cell.today
                            x: 3
                            y: 3
                            width: 6
                            height: 6
                            color: Theme.yellow
                        }
                        Text {
                            anchors.centerIn: parent
                            text: String(cell.day.getDate()).padStart(2, "0")
                            color: cell.today ? Theme.yellow : !cell.inMonth ? "#43454c" : cell.index >= 5 ? Theme.dim : Theme.ink
                            font.family: Theme.mono
                            font.weight: cell.today ? Font.Bold : Font.Normal
                            font.pixelSize: 13
                        }
                    }
                }
            }
        }
    }

    // upcoming
    Column {
        x: 18
        width: parent.width - 36
        topPadding: 10
        bottomPadding: 14
        spacing: 8
        SectionLabel {
            text: "UPCOMING"
        }
        Micro {
            text: "NO CALENDAR LINKED YET"
        }
    }
}
