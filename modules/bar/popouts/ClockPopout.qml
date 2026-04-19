pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root

    property date currentDate: new Date()

    readonly property int currMonth: currentDate.getMonth()
    readonly property int currYear: currentDate.getFullYear()

    spacing: Appearance.spacing.normal

    StyledText {
        text: Time.format("HH:mm:ss")
        font.family: Appearance.font.family.mono
        font.pointSize: Appearance.font.size.large
        font.weight: 500
        color: Colours.palette.m3primary
    }

    StyledText {
        text: Time.format("dddd, d MMMM yyyy")
        color: Colours.palette.m3onSurfaceVariant
        font.capitalization: Font.Capitalize
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.small

        Item {
            implicitWidth: implicitHeight
            implicitHeight: prevIcon.implicitHeight + Appearance.padding.small * 2

            StateLayer {
                radius: Appearance.rounding.full

                function onClicked(): void {
                    root.currentDate = new Date(root.currYear, root.currMonth - 1, 1);
                }
            }

            MaterialIcon {
                id: prevIcon

                anchors.centerIn: parent
                text: "chevron_left"
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.normal
                font.weight: 700
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: monthLabel.implicitHeight + Appearance.padding.small * 2

            StateLayer {
                radius: Appearance.rounding.full
                disabled: {
                    const now = new Date();
                    return root.currMonth === now.getMonth() && root.currYear === now.getFullYear();
                }

                function onClicked(): void {
                    root.currentDate = new Date();
                }
            }

            StyledText {
                id: monthLabel

                anchors.centerIn: parent
                text: grid.title
                color: Colours.palette.m3primary
                font.pointSize: Appearance.font.size.normal
                font.weight: 500
                font.capitalization: Font.Capitalize
            }
        }

        Item {
            implicitWidth: implicitHeight
            implicitHeight: nextIcon.implicitHeight + Appearance.padding.small * 2

            StateLayer {
                radius: Appearance.rounding.full

                function onClicked(): void {
                    root.currentDate = new Date(root.currYear, root.currMonth + 1, 1);
                }
            }

            MaterialIcon {
                id: nextIcon

                anchors.centerIn: parent
                text: "chevron_right"
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Appearance.font.size.normal
                font.weight: 700
            }
        }
    }

    DayOfWeekRow {
        Layout.fillWidth: true
        locale: grid.locale

        delegate: StyledText {
            required property var model

            horizontalAlignment: Text.AlignHCenter
            text: model.shortName
            font.weight: 500
            color: (model.day === 0 || model.day === 6) ? Colours.palette.m3secondary : Colours.palette.m3onSurfaceVariant
        }
    }

    MonthGrid {
        id: grid

        Layout.fillWidth: true

        month: root.currMonth
        year: root.currYear
        spacing: 3
        locale: Qt.locale()

        delegate: Item {
            id: dayItem

            required property var model

            implicitWidth: implicitHeight
            implicitHeight: dayText.implicitHeight + Appearance.padding.small * 2

            StyledRect {
                anchors.centerIn: parent
                visible: dayItem.model.today
                implicitWidth: parent.implicitWidth
                implicitHeight: parent.implicitHeight
                radius: Appearance.rounding.full
                color: Colours.palette.m3primary
            }

            StyledText {
                id: dayText

                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter
                text: grid.locale.toString(dayItem.model.day)
                color: {
                    if (dayItem.model.today)
                        return Colours.palette.m3onPrimary;
                    const dow = dayItem.model.date.getUTCDay();
                    if (dow === 0 || dow === 6)
                        return Colours.palette.m3secondary;
                    return Colours.palette.m3onSurfaceVariant;
                }
                opacity: dayItem.model.today || dayItem.model.month === grid.month ? 1 : 0.4
                font.pointSize: Appearance.font.size.normal
                font.weight: dayItem.model.today ? 700 : 500
            }
        }
    }
}
