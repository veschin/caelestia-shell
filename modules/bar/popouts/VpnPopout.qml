pragma ComponentBehavior: Bound

import qs.components
import Caelestia.Config
import qs.services
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    property bool amneziaActive: false
    property bool openconnectActive: false
    property string externalIp: ""
    property string country: ""
    property string city: ""

    spacing: Tokens.spacing.normal
    width: 220

    StyledText {
        text: qsTr("VPN Status")
        font.weight: 500
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: "shield"
            color: root.amneziaActive ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            font.pointSize: Tokens.font.size.normal
        }

        StyledText {
            Layout.fillWidth: true
            text: "AmneziaVPN"
            color: root.amneziaActive ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
        }

        StyledText {
            text: root.amneziaActive ? qsTr("On") : qsTr("Off")
            color: root.amneziaActive ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
            font.pointSize: Tokens.font.size.small
            font.family: Tokens.font.family.mono
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: "work"
            color: root.openconnectActive ? Colours.palette.m3tertiary : Colours.palette.m3onSurfaceVariant
            font.pointSize: Tokens.font.size.normal
        }

        StyledText {
            Layout.fillWidth: true
            text: "OpenConnect"
            color: root.openconnectActive ? Colours.palette.m3onSurface : Colours.palette.m3onSurfaceVariant
        }

        StyledText {
            text: root.openconnectActive ? qsTr("On") : qsTr("Off")
            color: root.openconnectActive ? Colours.palette.m3tertiary : Colours.palette.m3onSurfaceVariant
            font.pointSize: Tokens.font.size.small
            font.family: Tokens.font.family.mono
        }
    }

    RowLayout {
        visible: root.externalIp.length > 0
        Layout.fillWidth: true
        spacing: Tokens.spacing.small

        MaterialIcon {
            text: "language"
            color: Colours.palette.m3onSurfaceVariant
            font.pointSize: Tokens.font.size.normal
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            StyledText {
                text: root.externalIp
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Tokens.font.size.small
                font.family: Tokens.font.family.mono
            }

            StyledText {
                visible: root.country.length > 0
                text: root.city.length > 0 ? root.city + ", " + root.country : root.country
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Tokens.font.size.small
            }
        }
    }

    Timer {
        running: true
        repeat: true
        interval: 5000
        triggeredOnStart: true
        onTriggered: proc.running = true
    }

    Process {
        id: proc

        command: ["bash", Quickshell.env("HOME") + "/.local/bin/vpn-status.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    root.amneziaActive = data.amnesia.active;
                    root.openconnectActive = data.openconnect.active;
                    root.externalIp = data.externalIp || "";
                    root.country = data.country || "";
                    root.city = data.city || "";
                } catch (e) {}
            }
        }
    }
}
