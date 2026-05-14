pragma ComponentBehavior: Bound

import qs.components
import qs.services
import Caelestia.Config
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

    readonly property bool shielded: amneziaActive || openconnectActive
    readonly property bool doubleTunnel: amneziaActive && openconnectActive

    readonly property string heroIcon: doubleTunnel ? "verified_user" : (shielded ? "shield" : "shield")
    readonly property string heroCaption: doubleTunnel ? qsTr("double tunnel")
                                                       : shielded ? qsTr("protected")
                                                                  : qsTr("no protection")
    readonly property color heroBg: shielded ? Colours.palette.m3primaryContainer
                                             : Colours.palette.m3surfaceContainerHighest
    readonly property color heroFg: shielded ? Colours.palette.m3onPrimaryContainer
                                             : Colours.palette.m3onSurfaceVariant
    readonly property color captionColor: shielded ? Colours.palette.m3primary
                                                   : Colours.palette.m3onSurfaceVariant

    spacing: Tokens.spacing.larger
    width: 240

    // --- Header (centered) ---
    StyledText {
        Layout.alignment: Qt.AlignHCenter
        text: qsTr("VPN status")
        font.weight: 500
        font.pointSize: Tokens.font.size.normal
        color: Colours.palette.m3onSurface
    }

    // --- Hero: shield badge + caption ---
    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter
        spacing: Tokens.spacing.small

        StyledRect {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 64
            implicitHeight: 64
            radius: 32
            color: root.heroBg

            MaterialIcon {
                anchors.centerIn: parent
                text: root.heroIcon
                color: root.heroFg
                font.pointSize: Tokens.font.size.extraLarge
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: root.heroCaption
            font.weight: 500
            font.pointSize: Tokens.font.size.small
            color: root.captionColor
        }
    }

    // --- Status rows (centered grid) ---
    GridLayout {
        Layout.alignment: Qt.AlignHCenter
        columns: 3
        rowSpacing: Tokens.spacing.normal
        columnSpacing: Tokens.spacing.normal

        StyledRect {
            implicitWidth: 8
            implicitHeight: 8
            radius: 4
            Layout.alignment: Qt.AlignVCenter
            color: root.amneziaActive ? Colours.palette.m3primary
                                      : Colours.palette.m3outlineVariant
        }

        StyledText {
            text: "AmneziaVPN"
            font.pointSize: Tokens.font.size.small
            color: Colours.palette.m3onSurface
        }

        StyledText {
            Layout.alignment: Qt.AlignRight
            text: root.amneziaActive ? qsTr("active") : qsTr("off")
            font.pointSize: Tokens.font.size.small
            font.family: Tokens.font.family.mono
            font.weight: 500
            color: root.amneziaActive ? Colours.palette.m3primary
                                      : Colours.palette.m3onSurfaceVariant
        }

        StyledRect {
            implicitWidth: 8
            implicitHeight: 8
            radius: 4
            Layout.alignment: Qt.AlignVCenter
            color: root.openconnectActive ? Colours.palette.m3primary
                                          : Colours.palette.m3outlineVariant
        }

        StyledText {
            text: "OpenConnect"
            font.pointSize: Tokens.font.size.small
            color: Colours.palette.m3onSurface
        }

        StyledText {
            Layout.alignment: Qt.AlignRight
            text: root.openconnectActive ? qsTr("active") : qsTr("off")
            font.pointSize: Tokens.font.size.small
            font.family: Tokens.font.family.mono
            font.weight: 500
            color: root.openconnectActive ? Colours.palette.m3primary
                                          : Colours.palette.m3onSurfaceVariant
        }
    }

    // --- Footer: IP + country/city, centered ---
    ColumnLayout {
        Layout.fillWidth: true
        visible: root.externalIp.length > 0
        spacing: Tokens.spacing.small

        Rectangle {
            Layout.fillWidth: true
            Layout.bottomMargin: Tokens.spacing.smaller
            implicitHeight: 1
            color: Colours.palette.m3outlineVariant
            opacity: 0.5
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Tokens.spacing.normal

            StyledText {
                text: root.externalIp
                font.pointSize: Tokens.font.size.small
                font.family: Tokens.font.family.mono
                color: Colours.palette.m3onSurface
            }

            StyledRect {
                visible: root.country.length > 0
                color: Colours.palette.m3secondaryContainer
                radius: height / 2
                implicitWidth: countryText.implicitWidth + Tokens.spacing.normal * 2
                implicitHeight: countryText.implicitHeight + Tokens.spacing.smaller * 2

                StyledText {
                    id: countryText
                    anchors.centerIn: parent
                    text: root.country
                    color: Colours.palette.m3onSecondaryContainer
                    font.pointSize: Tokens.font.size.small
                    font.family: Tokens.font.family.mono
                    font.weight: 500
                }
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            visible: root.city.length > 0
            text: root.city
            font.pointSize: Tokens.font.size.small
            color: Colours.palette.m3onSurfaceVariant
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
