pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.config
import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    property real fiveHourUtil: -1
    property string resetsAt: ""
    property real lastFetchTime: 0
    property bool isLoading: false
    property bool hovered: mouseArea.containsMouse
    property int tick: 0

    property color colour: {
        if (fiveHourUtil >= 80) return Colours.palette.m3error;
        if (fiveHourUtil >= 50) return Colours.palette.m3tertiary;
        return Colours.palette.m3secondary;
    }

    property string resetStr: {
        void(tick);
        return formatReset(resetsAt);
    }

    property string tooltipStr: {
        if (fiveHourUtil < 0)
            return isLoading ? "загрузка..." : "нет данных";
        if (fiveHourUtil === 0)
            return "лимиты свободны";
        return Math.round(fiveHourUtil) + "%" + (resetStr ? " | сброс через " + resetStr : "");
    }

    function shouldFetch(): bool {
        return Date.now() - lastFetchTime > 120000;
    }

    function formatReset(iso: string): string {
        if (!iso) return "";
        const diff = new Date(iso) - new Date();
        if (diff <= 0) return "скоро";
        const h = Math.floor(diff / 3600000);
        const m = Math.floor((diff % 3600000) / 60000);
        if (h > 0) return h + "ч " + m + "м";
        return m + "м";
    }

    function parseData(raw: string): void {
        try {
            const data = JSON.parse(raw);
            if (!data.error && data.five_hour) {
                fiveHourUtil = data.five_hour.utilization;
                resetsAt = data.five_hour.resets_at ?? "";
            }
        } catch (e) {}
    }

    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

    onHoveredChanged: {
        if (hovered && shouldFetch()) {
            isLoading = true;
            limitsProc.running = true;
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton
    }

    // Read cache on startup + watch for external updates
    FileView {
        path: Quickshell.env("HOME") + "/.cache/claude-limits.json"
        onLoaded: root.parseData(text())
        watchChanges: true
        onFileChanged: reload()
    }

    // Periodic fetch every 2 minutes
    Timer {
        running: true
        repeat: true
        interval: 120000
        triggeredOnStart: true
        onTriggered: limitsProc.running = true
    }

    // Tick timer for resetStr freshness
    Timer {
        running: root.resetsAt !== ""
        repeat: true
        interval: 60000
        onTriggered: root.tick++
    }

    Column {
        id: col

        spacing: Appearance.spacing.small

        MaterialIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "smart_toy"
            color: root.colour

            SequentialAnimation on opacity {
                running: root.isLoading
                loops: Animation.Infinite
                alwaysRunToEnd: true

                Anim {
                    from: 1
                    to: 0.3
                    duration: Appearance.anim.durations.large
                    easing.bezierCurve: Appearance.anim.curves.standardAccel
                }
                Anim {
                    from: 0.3
                    to: 1
                    duration: Appearance.anim.durations.large
                    easing.bezierCurve: Appearance.anim.curves.standardDecel
                }
            }
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.fiveHourUtil >= 0
            text: Math.round(root.fiveHourUtil) + "%"
            font.pointSize: Appearance.font.size.small
            font.family: Appearance.font.family.mono
            color: root.colour
            horizontalAlignment: Text.AlignHCenter
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.resetStr !== ""
            text: root.resetStr
            font.pointSize: Appearance.font.size.smallest
            font.family: Appearance.font.family.mono
            color: root.colour
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Tooltip {
        target: root
        text: root.tooltipStr
    }

    Process {
        id: limitsProc
        command: ["bash", Quickshell.env("HOME") + "/.local/bin/claude-limits.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.isLoading = false;
                root.lastFetchTime = Date.now();
                root.parseData(text);
            }
        }
    }
}
