pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.launcher.items
import qs.modules.launcher.services

Item {
    id: root

    required property StyledTextField search
    required property DrawerVisibilities visibilities

    readonly property var currentList: state === "grid" ? gridLoader.item : listLoader.item

    implicitWidth: parent?.width ?? Tokens.sizes.launcher.itemWidth
    implicitHeight: (chipsRow.visible ? chipsRow.height + Tokens.spacing.small : 0) + contentArea.implicitHeight

    state: FileBrowser.viewMode === "grid" ? "grid" : "list"

    states: [
        State {
            name: "list"

            PropertyChanges {
                listLoader.active: true
                gridLoader.active: false
            }
        },
        State {
            name: "grid"

            PropertyChanges {
                listLoader.active: false
                gridLoader.active: true
            }
        }
    ]

    transitions: Transition {
        SequentialAnimation {
            ParallelAnimation {
                Anim {
                    target: contentArea
                    property: "opacity"
                    from: 1
                    to: 0
                    duration: Tokens.anim.durations.small
                    easing: Tokens.anim.standardAccel
                }
                Anim {
                    target: contentArea
                    property: "scale"
                    from: 1
                    to: 0.95
                    duration: Tokens.anim.durations.small
                    easing: Tokens.anim.standardAccel
                }
            }
            PropertyAction {
                targets: [listLoader, gridLoader]
                property: "active"
            }
            ParallelAnimation {
                Anim {
                    target: contentArea
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Tokens.anim.durations.small
                    easing: Tokens.anim.standardDecel
                }
                Anim {
                    target: contentArea
                    property: "scale"
                    from: 0.95
                    to: 1
                    duration: Tokens.anim.durations.small
                    easing: Tokens.anim.standardDecel
                }
            }
        }
    }

    Flow {
        id: chipsRow

        visible: FileBrowser.isActive && !FileBrowser.showQuickAccess
        height: visible ? implicitHeight : 0
        opacity: visible ? 1 : 0

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: Tokens.padding.normal
        anchors.rightMargin: Tokens.padding.normal

        spacing: Tokens.spacing.small
        topPadding: Tokens.padding.small
        bottomPadding: Tokens.padding.small

        component FilterChip: StyledRect {
            id: chip

            property string label
            property string iconName: ""
            property bool active
            signal toggled

            radius: Tokens.rounding.full
            color: active ? Colours.palette.m3secondaryContainer : "transparent"
            border.width: 1
            border.color: active ? Colours.palette.m3secondary : Colours.palette.m3outline

            implicitWidth: chipRow.implicitWidth + Tokens.padding.larger * 2
            implicitHeight: 28

            Row {
                id: chipRow
                anchors.centerIn: parent
                spacing: Tokens.spacing.small

                MaterialIcon {
                    visible: chip.iconName !== ""
                    text: chip.iconName
                    font.pointSize: Tokens.font.size.small
                    color: chip.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: chip.label
                    font.pointSize: Tokens.font.size.small
                    font.weight: chip.active ? 500 : 400
                    color: chip.active ? Colours.palette.m3onSecondaryContainer : Colours.palette.m3onSurfaceVariant
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            StateLayer {
                radius: chip.radius
                onClicked: chip.toggled()
            }
        }

        FilterChip {
            label: qsTr("All")
            active: FileBrowser.filterMode === "all"
            onToggled: FileBrowser.filterMode = "all"
        }

        FilterChip {
            label: qsTr("Images")
            iconName: "image"
            active: FileBrowser.filterMode === "images"
            onToggled: FileBrowser.filterMode = "images"
        }

        FilterChip {
            label: qsTr("List")
            iconName: "view_list"
            active: FileBrowser.viewMode === "list"
            onToggled: FileBrowser.viewMode = "list"
        }

        FilterChip {
            label: qsTr("Grid")
            iconName: "grid_view"
            active: FileBrowser.viewMode === "grid"
            onToggled: FileBrowser.viewMode = "grid"
        }

        FilterChip {
            label: qsTr("Name")
            iconName: "sort_by_alpha"
            active: FileBrowser.sortMode === "name"
            onToggled: FileBrowser.sortMode = "name"
        }

        FilterChip {
            label: qsTr("Size")
            iconName: "straighten"
            active: FileBrowser.sortMode === "size"
            onToggled: FileBrowser.sortMode = "size"
        }

        FilterChip {
            label: qsTr("Type")
            iconName: "category"
            active: FileBrowser.sortMode === "type"
            onToggled: FileBrowser.sortMode = "type"
        }

        FilterChip {
            label: qsTr("Date")
            iconName: "schedule"
            active: FileBrowser.sortMode === "date"
            onToggled: FileBrowser.sortMode = "date"
        }

        Behavior on height { Anim { type: Anim.StandardSmall } }
        Behavior on opacity { Anim { type: Anim.StandardSmall } }
    }

    Item {
        id: contentArea

        anchors.top: chipsRow.visible ? chipsRow.bottom : parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        implicitHeight: {
            if (root.state === "grid")
                return 350;
            const listH = listLoader.item?.implicitHeight ?? 0;
            return listH > 0 ? listH : empty.implicitHeight;
        }

        Loader {
            id: listLoader

            active: true
            anchors.fill: parent

            sourceComponent: FileBrowserList {
                search: root.search
                visibilities: root.visibilities
            }
        }

        Loader {
            id: gridLoader

            active: false
            anchors.fill: parent

            sourceComponent: FileBrowserGrid {
                visibilities: root.visibilities
            }
        }

        Row {
            id: empty

            opacity: root.currentList?.count === 0 ? 1 : 0
            scale: root.currentList?.count === 0 ? 1 : 0.5

            spacing: Tokens.spacing.normal
            padding: Tokens.padding.large

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            MaterialIcon {
                text: "folder_open"
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Tokens.font.size.extraLarge
                anchors.verticalCenter: parent.verticalCenter
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter

                StyledText {
                    text: qsTr("Empty directory")
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Tokens.font.size.larger
                    font.weight: 500
                }

                StyledText {
                    text: qsTr("Nothing here")
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Tokens.font.size.normal
                }
            }

            Behavior on opacity { Anim {} }
            Behavior on scale { Anim {} }
        }
    }

    FileContextMenu {
        id: contextMenu
        visibilities: root.visibilities
    }

    Connections {
        target: FileBrowser

        function onContextMenuRequested(entry, screenX, screenY): void {
            contextMenu.showAt(entry, screenX, screenY);
        }
    }
}
