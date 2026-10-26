// Control center CALENDAR tab = the calendar mock (ds-topbar-v2 ?state=cal): month header with ‹ ›, ISO week
// column, Monday-first grid, today boxed in yellow, cyan marks on days with events, an upcoming list, ISO footer.
// Events come from Felt (felt-tray's D-Bus property org.clockmost.Felt.Agenda, which felt-core fills from Google
// Calendar - Mario 2026-10-15: one Google login, Felt does the reminders, the bar only shows). Click a day = that
// day's events; click it again = upcoming. An event with a meeting link opens it.
import QtQuick
import Quickshell
import Quickshell.Io

CCTab {
    id: root

    property int monthOffset: 0 // 0 = this month
    property var events: [] // [{title, calendar, start, end, all_day, location, link}]
    property bool feltUp: false
    property string selected: "" // "YYYY-MM-DD", "" = upcoming from now
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
    function key(d) {
        return d.getFullYear() + "-" + String(d.getMonth() + 1).padStart(2, "0") + "-" + String(d.getDate()).padStart(2, "0");
    }
    // the local day an event starts on (all-day: its date as given)
    function eventDay(e) {
        return e.all_day ? e.start.slice(0, 10) : key(new Date(e.start));
    }
    function hasEvents(d) {
        const k = key(d);
        return events.some(e => eventDay(e) === k);
    }
    readonly property var shown: {
        if (selected !== "")
            return events.filter(e => eventDay(e) === selected);
        const nowMs = now.getTime();
        return events.filter(e => (e.all_day ? new Date(e.end + "T00:00:00") : new Date(e.end || e.start)).getTime() > nowMs).slice(0, 6);
    }
    function whenText(e) {
        const day = e.all_day ? new Date(e.start + "T00:00:00") : new Date(e.start);
        const d = sameDay(day, now) ? "TODAY" : Qt.formatDate(day, "ddd dd").toUpperCase();
        return e.all_day ? d + " · ALL DAY" : d + " · " + Qt.formatTime(day, "HH:mm");
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

    Process {
        id: agenda
        command: ["busctl", "--user", "--json=short", "get-property", "org.clockmost.Felt", "/org/clockmost/Felt", "org.clockmost.Felt", "Agenda"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.events = JSON.parse(JSON.parse(text).data);
                    root.feltUp = true;
                } catch (e) {
                    root.feltUp = false;
                }
            }
        }
        onExited: code => {
            if (code !== 0)
                root.feltUp = false;
        }
    }
    Timer {
        interval: 60000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: agenda.running = true
    }

    // month header: OCTOBER 2026 (year dim, regular) + ‹ ›
    // v2: the month as the poster lead, year dim beside it, a bone rule under
    Item {
        width: parent.width
        height: 96
        Row {
            x: 22
            y: 14
            spacing: 12
            Text {
                text: Qt.formatDate(root.first, "MMMM").toUpperCase()
                color: Theme.ink
                font.family: GroundTheme.display
                font.weight: Font.Black
                font.variableAxes: { "wdth": 68, "wght": 900 }
                font.pixelSize: 64
            }
            Text {
                anchors.baseline: parent.children[0].baseline
                text: root.first.getFullYear()
                color: Theme.dim
                font.family: GroundTheme.display
                font.weight: Font.Black
                font.variableAxes: { "wdth": 68, "wght": 900 }
                font.pixelSize: 64
            }
        }
        Rectangle { x: 22; anchors.bottom: parent.bottom; width: parent.width - 44; height: 2; color: Theme.ink }
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 22
            y: 34
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
                    border.color: GroundTheme.line
                    Text {
                        anchors.centerIn: parent
                        text: nav.modelData.t
                        color: nav.modelData.d === 0 && root.monthOffset !== 0 ? GroundTheme.acc : Theme.ink2
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
        x: 22
        width: parent.width - 44
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
                        // selected day: a faint plate
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 3
                            visible: root.selected === root.key(cell.day)
                            color: Qt.rgba(1, 1, 1, 0.08)
                        }
                        // has events: a small cyan square under the number
                        Rectangle {
                            visible: root.hasEvents(cell.day)
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: parent.height - 9
                            width: 4
                            height: 4
                            color: cell.inMonth ? Theme.cyan : "#43454c"
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.selected = root.selected === root.key(cell.day) ? "" : root.key(cell.day)
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
        x: 22
        width: parent.width - 44
        topPadding: 10
        bottomPadding: 14
        spacing: 8
        SectionLabel {
            text: root.selected === "" ? "UPCOMING" : Qt.formatDate(new Date(root.selected + "T00:00:00"), "dddd dd MMMM").toUpperCase()
        }
        Micro {
            visible: root.shown.length === 0
            text: !root.feltUp ? "FELT ISN'T RUNNING - NO CALENDAR" : root.selected === "" ? "NOTHING COMING UP" : "NOTHING THAT DAY"
        }
        Repeater {
            model: root.shown
            Item {
                id: ev
                required property var modelData
                width: parent.width
                height: 34
                Rectangle {
                    anchors.fill: parent
                    color: evArea.containsMouse && ev.modelData.link ? Qt.rgba(1, 1, 1, 0.06) : "transparent"
                }
                Rectangle {
                    width: 2
                    height: parent.height - 6
                    anchors.verticalCenter: parent.verticalCenter
                    color: ev.modelData.all_day ? Theme.dim : Theme.cyan
                }
                Column {
                    x: 10
                    width: parent.width - 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text {
                        width: parent.width
                        elide: Text.ElideRight
                        text: ev.modelData.title + (ev.modelData.link ? "  ↗" : "")
                        color: Theme.ink
                        font.family: Theme.body
                        font.pixelSize: 12
                    }
                    Micro {
                        width: parent.width
                        elide: Text.ElideRight
                        text: root.whenText(ev.modelData) + "  ·  " + ev.modelData.calendar
                        color: Theme.dim
                    }
                }
                MouseArea {
                    id: evArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: ev.modelData.link ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: if (ev.modelData.link) Qt.openUrlExternally(ev.modelData.link)
                }
            }
        }
    }
}
