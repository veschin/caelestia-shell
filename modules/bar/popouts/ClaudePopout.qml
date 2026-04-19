pragma ComponentBehavior: Bound

import qs.components
import qs.config
import qs.services
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

    function formatReset(iso: string): string {
        if (!iso) return "";
        const diff = new Date(iso) - new Date();
        if (diff <= 0) return "soon";
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

    FileView {
        path: Quickshell.env("HOME") + "/.cache/claude-limits.json"
        onLoaded: root.parseData(text())
        watchChanges: true
        onFileChanged: reload()
    }

    spacing: Appearance.spacing.normal
    width: 220

    StyledText {
        text: qsTr("Claude Code Usage")
        font.weight: 500
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.smaller

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            StyledText {
                text: qsTr("5-hour")
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.small
            }

            Item { Layout.fillWidth: true }

            StyledText {
                text: root.fiveHourUtil >= 0 ? Math.round(root.fiveHourUtil) + "%" : "N/A"
                color: {
                    if (root.fiveHourUtil < 0) return Colours.palette.m3onSurfaceVariant;
                    if (root.fiveHourUtil < 50) return Colours.palette.m3onSurface;
                    if (root.fiveHourUtil < 80) return Colours.palette.m3tertiary;
                    return Colours.palette.m3error;
                }
                font.pointSize: Appearance.font.size.small
                font.family: Appearance.font.family.mono
                font.weight: 500
            }
        }

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: 4
            radius: 2
            color: Colours.palette.m3surfaceContainerHighest

            StyledRect {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                implicitWidth: root.fiveHourUtil >= 0 ? parent.width * (root.fiveHourUtil / 100) : 0
                radius: 2
                color: {
                    if (root.fiveHourUtil < 50) return Colours.palette.m3primary;
                    if (root.fiveHourUtil < 80) return Colours.palette.m3tertiary;
                    return Colours.palette.m3error;
                }

                Behavior on implicitWidth { Anim {} }
            }
        }

        StyledText {
            visible: root.fiveHourReset !== ""
            text: "resets in " + root.formatReset(root.fiveHourReset)
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Appearance.font.size.small
            font.family: Appearance.font.family.mono
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.smaller

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.small

            StyledText {
                text: qsTr("7-day")
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.small
            }

            Item { Layout.fillWidth: true }

            StyledText {
                text: root.sevenDayUtil >= 0 ? Math.round(root.sevenDayUtil) + "%" : "N/A"
                color: {
                    if (root.sevenDayUtil < 0) return Colours.palette.m3onSurfaceVariant;
                    if (root.sevenDayUtil < 50) return Colours.palette.m3onSurface;
                    if (root.sevenDayUtil < 80) return Colours.palette.m3tertiary;
                    return Colours.palette.m3error;
                }
                font.pointSize: Appearance.font.size.small
                font.family: Appearance.font.family.mono
                font.weight: 500
            }
        }

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: 4
            radius: 2
            color: Colours.palette.m3surfaceContainerHighest

            StyledRect {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                implicitWidth: root.sevenDayUtil >= 0 ? parent.width * (root.sevenDayUtil / 100) : 0
                radius: 2
                color: {
                    if (root.sevenDayUtil < 50) return Colours.palette.m3primary;
                    if (root.sevenDayUtil < 80) return Colours.palette.m3tertiary;
                    return Colours.palette.m3error;
                }

                Behavior on implicitWidth { Anim {} }
            }
        }

        StyledText {
            visible: root.sevenDayReset !== ""
            text: "resets in " + root.formatReset(root.sevenDayReset)
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Appearance.font.size.small
            font.family: Appearance.font.family.mono
        }
    }

    RowLayout {
        visible: root.subscription.length > 0
        Layout.fillWidth: true
        spacing: Appearance.spacing.small

        StyledText {
            text: root.subscription
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Appearance.font.size.small
            font.family: Appearance.font.family.mono
        }

        Item { Layout.fillWidth: true }

        StyledText {
            visible: root.rateTier.length > 0
            text: root.rateTier
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Appearance.font.size.small
            font.family: Appearance.font.family.mono
        }
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
}
