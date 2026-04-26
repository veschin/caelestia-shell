import QtQuick
import QtQuick.Controls
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.launcher.services

Popup {
    id: root

    property var entry: null
    required property DrawerVisibilities visibilities

    padding: Tokens.padding.small
    width: 220

    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside | Popup.CloseOnPressOutsideParent

    function showAt(entry, screenX: real, screenY: real): void {
        root.entry = entry;
        const localPos = root.parent.mapFromGlobal(screenX, screenY);
        root.x = localPos.x;
        root.y = localPos.y;
        root.open();
    }

    background: StyledRect {
        color: Colours.palette.m3surfaceContainer
        radius: Tokens.rounding.normal
        border.width: 1
        border.color: Colours.palette.m3outlineVariant
    }

    contentItem: Column {
        spacing: 2

        component MenuItem: Item {
            id: menuItem

            property string label
            property string iconName
            signal triggered

            width: parent.width
            implicitHeight: 36

            StateLayer {
                radius: Tokens.rounding.small
                onClicked: {
                    menuItem.triggered();
                    root.close();
                }
            }

            Row {
                anchors.fill: parent
                anchors.leftMargin: Tokens.padding.normal
                anchors.rightMargin: Tokens.padding.normal
                spacing: Tokens.spacing.normal

                MaterialIcon {
                    text: menuItem.iconName
                    font.pointSize: Tokens.font.size.normal
                    color: Colours.palette.m3onSurfaceVariant
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: menuItem.label
                    font.pointSize: Tokens.font.size.small
                    color: Colours.palette.m3onSurface
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }

        MenuItem {
            label: qsTr("Copy path")
            iconName: "content_copy"
            onTriggered: Quickshell.execDetached(["wl-copy", root.entry.path])
        }

        MenuItem {
            label: qsTr("Copy file")
            iconName: "file_copy"
            onTriggered: {
                const mime = (root.entry.mimeType ?? "application/octet-stream").replace(/'/g, "'\\''");
                const path = root.entry.path.replace(/'/g, "'\\''");
                Quickshell.execDetached(["sh", "-c", "wl-copy --type '" + mime + "' < '" + path + "'"]);
            }
            visible: root.entry ? !root.entry.isDir : false
        }

        Rectangle {
            width: parent.width
            height: 1
            color: Colours.palette.m3outlineVariant
        }

        MenuItem {
            label: qsTr("Open terminal here")
            iconName: "terminal"
            onTriggered: {
                const dir = root.entry.isDir ? root.entry.path : root.entry.parentDir;
                FileBrowser.openTerminal(dir);
                root.visibilities.launcher = false;
            }
        }

        MenuItem {
            label: qsTr("Open in file manager")
            iconName: "folder_open"
            onTriggered: {
                const dir = root.entry.isDir ? root.entry.path : root.entry.parentDir;
                Quickshell.execDetached(["xdg-open", dir]);
                root.visibilities.launcher = false;
            }
        }

        MenuItem {
            label: qsTr("Open with...")
            iconName: "open_in_new"
            onTriggered: {
                Quickshell.execDetached(["xdg-open", root.entry.path]);
                root.visibilities.launcher = false;
            }
            visible: root.entry ? !root.entry.isDir : false
        }
    }
}
