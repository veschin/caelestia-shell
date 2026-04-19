pragma ComponentBehavior: Bound

import qs.components
import qs.config
import Quickshell
import Quickshell.Io
import QtQuick

Column {
    id: root

    property bool anyActive: false
    property bool amneziaActive: false
    property bool openconnectActive: false
    property color colour: anyActive ? Colours.palette.m3primary : Colours.palette.m3surfaceContainerHighest

    spacing: Appearance.spacing.small

    MaterialIcon {
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.anyActive ? "vpn_key" : "vpn_key_off"
        color: root.colour
    }

    MaterialIcon {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.amneziaActive
        text: "shield"
        color: Colours.palette.m3primary
        font.pointSize: Appearance.font.size.smaller
    }

    MaterialIcon {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.openconnectActive
        text: "work"
        color: Colours.palette.m3tertiary
        font.pointSize: Appearance.font.size.smaller
    }

    Timer {
        running: true
        repeat: true
        interval: 5000
        triggeredOnStart: true
        onTriggered: statusProc.running = true
    }

    Process {
        id: statusProc
        command: ["bash", Quickshell.env("HOME") + "/.local/bin/vpn-status.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    root.amneziaActive = data.amnesia.active;
                    root.openconnectActive = data.openconnect.active;
                    root.anyActive = data.anyActive;
                } catch (e) {
                    root.anyActive = false;
                }
            }
        }
    }
}
