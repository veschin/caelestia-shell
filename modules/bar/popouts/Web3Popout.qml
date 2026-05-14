pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import Caelestia.Config
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    property string started: "2026-05-06"
    property string deadline: "2027-01-15"
    property string currentMilestone: ""
    property string lastSession: ""
    property int totalSessions: 90
    property int sessionsDone: 0
    property var doneDays: ({})
    property int tick: 0
    property date displayMonth: new Date()

    readonly property real sessionProgress: totalSessions ? sessionsDone / totalSessions : 0

    readonly property int daysLeft: {
        void(tick);
        return Math.max(0, Math.floor((new Date(deadline).getTime() - Date.now()) / 86400000));
    }

    readonly property int weeksLeft: Math.floor(daysLeft / 7)

    readonly property int monthsLeft: {
        void(tick);
        const n = new Date();
        const d = new Date(deadline);
        const m = (d.getFullYear() - n.getFullYear()) * 12 + (d.getMonth() - n.getMonth());
        return Math.max(0, d.getDate() < n.getDate() ? m - 1 : m);
    }

    readonly property string todayIso: {
        void(tick);
        return root.isoOf(new Date());
    }

    readonly property int displayYear: displayMonth.getFullYear()
    readonly property int displayMonthIdx: displayMonth.getMonth()
    readonly property int daysInMonth: new Date(displayYear, displayMonthIdx + 1, 0).getDate()
    readonly property int firstOffset: ((new Date(displayYear, displayMonthIdx, 1).getDay()) + 6) % 7

    readonly property var monthNames: [
        "январь", "февраль", "март", "апрель",
        "май", "июнь", "июль", "август",
        "сентябрь", "октябрь", "ноябрь", "декабрь"
    ]

    readonly property var weekdayShort: ["пн", "вт", "ср", "чт", "пт", "сб", "вс"]

    function isoOf(d: date): string {
        const y = d.getFullYear();
        const m = String(d.getMonth() + 1).padStart(2, '0');
        const day = String(d.getDate()).padStart(2, '0');
        return y + "-" + m + "-" + day;
    }

    function dayWord(n: int): string {
        const mod10 = n % 10;
        const mod100 = n % 100;
        if (mod10 === 1 && mod100 !== 11) return qsTr("день");
        if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return qsTr("дня");
        return qsTr("дней");
    }

    function weekWord(n: int): string {
        const mod10 = n % 10;
        const mod100 = n % 100;
        if (mod10 === 1 && mod100 !== 11) return qsTr("неделя");
        if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return qsTr("недели");
        return qsTr("недель");
    }

    function monthWord(n: int): string {
        const mod10 = n % 10;
        const mod100 = n % 100;
        if (mod10 === 1 && mod100 !== 11) return qsTr("месяц");
        if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return qsTr("месяца");
        return qsTr("месяцев");
    }

    function shiftMonth(delta: int): void {
        const d = new Date(displayMonth);
        d.setDate(1);
        d.setMonth(d.getMonth() + delta);
        displayMonth = d;
    }

    function parseData(raw: string): void {
        try {
            const data = JSON.parse(raw);
            started = data.started ?? started;
            deadline = data.deadline ?? deadline;
            currentMilestone = data.current_milestone ?? "";
            totalSessions = data.total_sessions ?? totalSessions;
            const arr = Array.isArray(data.sessions) ? data.sessions : [];
            const done = arr.filter(s => s && s.status === "done");
            sessionsDone = done.length;
            if (done.length > 0) {
                const ids = done.map(s => parseInt((s.id || "S0").substring(1)) || 0);
                const maxId = Math.max(0, ...ids);
                lastSession = "S" + String(maxId).padStart(2, '0');
            } else {
                lastSession = "";
            }
            const dayMap = {};
            for (const s of done) {
                if (s.date) dayMap[s.date] = (dayMap[s.date] || 0) + 1;
            }
            doneDays = dayMap;
        } catch (e) {}
    }

    spacing: Tokens.spacing.larger
    width: 280

    FileView {
        path: "/home/veschin/work/web3/progress.json"
        watchChanges: true
        onLoaded: root.parseData(text())
        onFileChanged: reload()
    }

    Timer {
        running: true
        repeat: true
        interval: 60000
        onTriggered: root.tick++
    }

    // --- Header ---
    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Tokens.spacing.smaller

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("Web3 plan")
            font.weight: 500
            font.pointSize: Tokens.font.size.normal
            color: Colours.palette.m3onSurface
        }

        StyledRect {
            Layout.alignment: Qt.AlignHCenter
            visible: root.currentMilestone.length > 0 || root.lastSession.length > 0
            color: Colours.palette.m3secondaryContainer
            radius: height / 2
            implicitWidth: badgeText.implicitWidth + Tokens.spacing.normal * 2
            implicitHeight: badgeText.implicitHeight + Tokens.spacing.smaller * 2

            StyledText {
                id: badgeText
                anchors.centerIn: parent
                text: {
                    const parts = [];
                    if (root.currentMilestone) parts.push(root.currentMilestone);
                    if (root.lastSession) parts.push(root.lastSession);
                    return parts.join(" · ");
                }
                color: Colours.palette.m3onSecondaryContainer
                font.pointSize: Tokens.font.size.small
                font.family: Tokens.font.family.mono
                font.weight: 500
            }
        }
    }

    // --- Hero: circle with % + session counter ---
    Item {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: 104
        implicitHeight: 104

        CircularProgress {
            anchors.fill: parent
            value: root.sessionProgress
            strokeWidth: 7
            spacing: Tokens.spacing.small
            fgColour: Colours.palette.m3primary
            bgColour: Colours.palette.m3surfaceContainerHighest
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 0

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: Math.round(root.sessionProgress * 100) + "%"
                font.pointSize: Tokens.font.size.extraLarge
                font.weight: 500
                color: Colours.palette.m3primary
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.sessionsDone + " / " + root.totalSessions
                font.pointSize: Tokens.font.size.small
                font.family: Tokens.font.family.mono
                color: Qt.alpha(Colours.palette.m3primary, 0.85)
            }
        }
    }

    // --- Stat cards: days, weeks, months left (equal-width, centered group) ---
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Tokens.spacing.larger

        ColumnLayout {
            Layout.preferredWidth: 64
            spacing: 0

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.daysLeft
                font.pointSize: Tokens.font.size.large
                font.weight: 500
                font.family: Tokens.font.family.mono
                color: Colours.palette.m3primary
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.dayWord(root.daysLeft)
                font.pointSize: Tokens.font.size.small
                color: Qt.alpha(Colours.palette.m3primary, 0.75)
            }
        }

        ColumnLayout {
            Layout.preferredWidth: 64
            spacing: 0

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.weeksLeft
                font.pointSize: Tokens.font.size.large
                font.weight: 500
                font.family: Tokens.font.family.mono
                color: Colours.palette.m3primary
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.weekWord(root.weeksLeft)
                font.pointSize: Tokens.font.size.small
                color: Qt.alpha(Colours.palette.m3primary, 0.75)
            }
        }

        ColumnLayout {
            Layout.preferredWidth: 64
            spacing: 0

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.monthsLeft
                font.pointSize: Tokens.font.size.large
                font.weight: 500
                font.family: Tokens.font.family.mono
                color: Colours.palette.m3primary
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: root.monthWord(root.monthsLeft)
                font.pointSize: Tokens.font.size.small
                color: Qt.alpha(Colours.palette.m3primary, 0.75)
            }
        }
    }

    // --- Month navigator ---
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Tokens.spacing.normal

        Item {
            implicitWidth: 24
            implicitHeight: 24

            MaterialIcon {
                anchors.centerIn: parent
                text: "chevron_left"
                color: Qt.alpha(Colours.palette.m3primary, 0.7)
                font.pointSize: Tokens.font.size.larger
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.shiftMonth(-1)
            }
        }

        Item {
            Layout.preferredWidth: 130
            Layout.preferredHeight: monthTitle.implicitHeight

            StyledText {
                id: monthTitle
                anchors.fill: parent
                horizontalAlignment: Text.AlignHCenter
                text: root.monthNames[root.displayMonthIdx] + " " + root.displayYear
                font.weight: 500
                font.pointSize: Tokens.font.size.normal
                color: Colours.palette.m3onSurface
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.displayMonth = new Date()
            }
        }

        Item {
            implicitWidth: 24
            implicitHeight: 24

            MaterialIcon {
                anchors.centerIn: parent
                text: "chevron_right"
                color: Qt.alpha(Colours.palette.m3primary, 0.7)
                font.pointSize: Tokens.font.size.larger
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.shiftMonth(1)
            }
        }
    }

    // --- Calendar grid ---
    GridLayout {
        Layout.alignment: Qt.AlignHCenter
        columns: 7
        rowSpacing: 4
        columnSpacing: 4

        Repeater {
            model: root.weekdayShort

            StyledText {
                required property var modelData
                Layout.preferredWidth: 32
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                font.pointSize: Tokens.font.size.small
                font.family: Tokens.font.family.mono
                color: Qt.alpha(Colours.palette.m3primary, 0.7)
            }
        }

        Repeater {
            model: root.firstOffset

            Item {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
            }
        }

        Repeater {
            model: root.daysInMonth

            StyledRect {
                required property int index

                readonly property int dayNum: index + 1
                readonly property string isoDate: root.displayYear + "-"
                    + String(root.displayMonthIdx + 1).padStart(2, '0') + "-"
                    + String(dayNum).padStart(2, '0')
                readonly property bool hasSession: (root.doneDays[isoDate] || 0) > 0
                readonly property bool isToday: isoDate === root.todayIso

                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: 8
                color: hasSession ? Colours.palette.m3primaryContainer : "transparent"
                border.width: isToday ? 1.5 : 0
                border.color: Colours.palette.m3primary

                StyledText {
                    anchors.centerIn: parent
                    text: parent.dayNum
                    font.pointSize: Tokens.font.size.small
                    font.weight: parent.isToday || parent.hasSession ? 500 : 400
                    font.family: Tokens.font.family.mono
                    color: parent.hasSession ? Colours.palette.m3onPrimaryContainer
                         : parent.isToday ? Colours.palette.m3primary
                         : Qt.alpha(Colours.palette.m3primary, 0.8)
                }
            }
        }
    }
}
