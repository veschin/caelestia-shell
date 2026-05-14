pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import Caelestia.Config
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    property real fiveHourUtil: -1
    property real sevenDayUtil: -1
    property string subscription: ""
    property string rateTier: ""
    property string fiveHourReset: ""
    property string sevenDayReset: ""

    readonly property string pillLabel: {
        const parts = [];
        if (subscription) parts.push(subscription);
        if (rateTier) {
            const cleaned = rateTier.replace(/^default_claude_/, "").replace(/_/g, " ");
            const tail = cleaned.split(" ").pop();
            if (tail && tail !== subscription) parts.push(tail);
        }
        return parts.join(" · ");
    }

    function colorFor(util: real): color {
        if (util < 0) return Colours.palette.m3onSurfaceVariant;
        if (util >= 80) return Colours.palette.m3error;
        if (util >= 50) return Colours.palette.m3tertiary;
        return Colours.palette.m3primary;
    }

    function formatReset(iso: string): string {
        if (!iso) return "";
        const diff = new Date(iso) - new Date();
        if (diff <= 0) return qsTr("soon");
        const d = Math.floor(diff / 86400000);
        const h = Math.floor((diff % 86400000) / 3600000);
        const m = Math.floor((diff % 3600000) / 60000);
        if (d > 0) return d + "d " + h + "h";
        if (h > 0) return h + "h " + m + "m";
        return m + "m";
    }

    function parseData(raw: string): void {
        try {
            const data = JSON.parse(raw);
            if (!data.error) {
                root.fiveHourUtil = data.five_hour ? data.five_hour.utilization : -1;
                root.sevenDayUtil = data.seven_day ? data.seven_day.utilization : -1;
                root.fiveHourReset = data.five_hour ? (data.five_hour.resets_at ?? "") : "";
                root.sevenDayReset = data.seven_day ? (data.seven_day.resets_at ?? "") : "";
                root.subscription = data.subscription || "";
                root.rateTier = data.rateTier || "";
            }
        } catch (e) {}
    }

    spacing: Tokens.spacing.larger
    width: 240

    FileView {
        path: Quickshell.env("HOME") + "/.cache/claude-limits.json"
        onLoaded: root.parseData(text())
        watchChanges: true
        onFileChanged: reload()
    }

    Timer {
        running: true
        repeat: true
        interval: 300000
        triggeredOnStart: true
        onTriggered: proc.running = true
    }

    Process {
        id: proc
        command: ["bash", Quickshell.env("HOME") + "/.local/bin/claude-limits.sh"]
        stdout: StdioCollector {
            onStreamFinished: root.parseData(text)
        }
    }

    // --- Header (centered: title + pill stacked) ---
    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Tokens.spacing.smaller

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: qsTr("Claude Code")
            font.weight: 500
            font.pointSize: Tokens.font.size.normal
            color: Colours.palette.m3onSurface
        }

        StyledRect {
            Layout.alignment: Qt.AlignHCenter
            visible: root.pillLabel.length > 0
            color: Colours.palette.m3secondaryContainer
            radius: height / 2
            implicitWidth: pillText.implicitWidth + Tokens.spacing.normal * 2
            implicitHeight: pillText.implicitHeight + Tokens.spacing.smaller * 2

            StyledText {
                id: pillText
                anchors.centerIn: parent
                text: root.pillLabel
                color: Colours.palette.m3onSecondaryContainer
                font.pointSize: Tokens.font.size.small
                font.family: Tokens.font.family.mono
                font.weight: 500
            }
        }
    }

    // --- Hero: two symmetric gauges ---
    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Tokens.spacing.large

        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: Tokens.spacing.small

            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 68
                implicitHeight: 68

                CircularProgress {
                    anchors.fill: parent
                    value: root.fiveHourUtil >= 0 ? root.fiveHourUtil / 100 : 0
                    strokeWidth: 5
                    spacing: Tokens.spacing.small
                    fgColour: root.colorFor(root.fiveHourUtil)
                    bgColour: Colours.palette.m3surfaceContainerHighest
                }

                StyledText {
                    anchors.centerIn: parent
                    text: root.fiveHourUtil >= 0 ? Math.round(root.fiveHourUtil) + "%" : "-"
                    font.pointSize: Tokens.font.size.larger
                    font.weight: 500
                    color: root.colorFor(root.fiveHourUtil)
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("5-hour")
                font.pointSize: Tokens.font.size.small
                color: Colours.palette.m3onSurface
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                visible: root.fiveHourReset.length > 0
                text: qsTr("in ") + root.formatReset(root.fiveHourReset)
                font.pointSize: Tokens.font.size.small
                font.family: Tokens.font.family.mono
                color: Colours.palette.m3onSurfaceVariant
            }
        }

        ColumnLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: Tokens.spacing.small

            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 68
                implicitHeight: 68

                CircularProgress {
                    anchors.fill: parent
                    value: root.sevenDayUtil >= 0 ? root.sevenDayUtil / 100 : 0
                    strokeWidth: 5
                    spacing: Tokens.spacing.small
                    fgColour: root.colorFor(root.sevenDayUtil)
                    bgColour: Colours.palette.m3surfaceContainerHighest
                }

                StyledText {
                    anchors.centerIn: parent
                    text: root.sevenDayUtil >= 0 ? Math.round(root.sevenDayUtil) + "%" : "-"
                    font.pointSize: Tokens.font.size.larger
                    font.weight: 500
                    color: root.colorFor(root.sevenDayUtil)
                }
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                text: qsTr("7-day")
                font.pointSize: Tokens.font.size.small
                color: Colours.palette.m3onSurface
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                visible: root.sevenDayReset.length > 0
                text: qsTr("in ") + root.formatReset(root.sevenDayReset)
                font.pointSize: Tokens.font.size.small
                font.family: Tokens.font.family.mono
                color: Colours.palette.m3onSurfaceVariant
            }
        }
    }
}
