pragma ComponentBehavior: Bound

import QtQuick
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services
import qs.modules.launcher.services

Item {
    id: root

    required property DrawerVisibilities visibilities
    required property var panels
    required property real maxHeight

    readonly property int padding: Tokens.padding.large
    readonly property int rounding: Tokens.rounding.large

    implicitWidth: listWrapper.width + padding * 2
    implicitHeight: searchWrapper.height + listWrapper.height + padding * 2

    Item {
        id: listWrapper

        implicitWidth: list.width
        implicitHeight: list.height + root.padding

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: searchWrapper.top
        anchors.bottomMargin: root.padding

        ContentList {
            id: list

            content: root
            visibilities: root.visibilities
            panels: root.panels
            maxHeight: root.maxHeight - searchWrapper.implicitHeight - root.padding * 3
            search: search
            padding: root.padding
            rounding: root.rounding
        }

        Connections {
            target: FileBrowser

            function onFileActivated(entry): void {
                if (entry.isDir) {
                    FileBrowser.navigateInto(entry.name);
                    search.text = FileBrowser.rawInput;
                } else if (entry.isImage && FileBrowser.viewMode === "grid") {
                    const images = FileBrowser.imageList();
                    const idx = images.findIndex(e => e.path === entry.path);
                    quickLook.open(images, Math.max(0, idx));
                } else {
                    FileBrowser.openFile(entry.path);
                    root.visibilities.launcher = false;
                }
            }
        }
    }

    QuickLook {
        id: quickLook

        anchors.fill: parent
        searchField: search
        visibilities: root.visibilities
    }

    StyledRect {
        id: searchWrapper

        color: Colours.layer(Colours.palette.m3surfaceContainer, 2)
        radius: Tokens.rounding.full

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: root.padding

        implicitHeight: Math.max(searchIcon.implicitHeight, search.implicitHeight, clearIcon.implicitHeight)

        MaterialIcon {
            id: searchIcon

            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: root.padding

            text: "search"
            color: Colours.palette.m3onSurfaceVariant
        }

        StyledTextField {
            id: search

            anchors.left: searchIcon.right
            anchors.right: clearIcon.left
            anchors.leftMargin: Tokens.spacing.small
            anchors.rightMargin: Tokens.spacing.small

            topPadding: Tokens.padding.larger
            bottomPadding: Tokens.padding.larger

            placeholderText: qsTr("Type \"%1\" for commands").arg(GlobalConfig.launcher.actionPrefix)

            onTextChanged: FileBrowser.parseInput(text)

            onAccepted: {
                if (FileBrowser.isActive) {
                    const currentItem = list.currentList?.currentItem;
                    if (!currentItem)
                        return;
                    const entry = currentItem.modelData;

                    if (entry.isDir) {
                        FileBrowser.navigateInto(entry.name);
                        text = FileBrowser.rawInput;
                        return;
                    }
                    if (entry.isImage && FileBrowser.viewMode === "grid") {
                        const images = FileBrowser.imageList();
                        const idx = images.findIndex(e => e.path === entry.path);
                        quickLook.open(images, Math.max(0, idx));
                        return;
                    }
                    FileBrowser.openFile(entry.path);
                    root.visibilities.launcher = false;
                    return;
                }

                const currentItem = list.currentList?.currentItem;
                if (currentItem) {
                    if (list.showWallpapers) {
                        if (Colours.scheme === "dynamic" && currentItem.modelData.path !== Wallpapers.actualCurrent)
                            Wallpapers.previewColourLock = true;
                        Wallpapers.setWallpaper(currentItem.modelData.path);
                        root.visibilities.launcher = false;
                    } else if (text.startsWith(GlobalConfig.launcher.actionPrefix)) {
                        if (text.startsWith(`${GlobalConfig.launcher.actionPrefix}calc `))
                            currentItem.onClicked();
                        else
                            currentItem.modelData.onClicked(list.currentList);
                    } else {
                        Apps.launch(currentItem.modelData);
                        root.visibilities.launcher = false;
                    }
                }
            }

            Keys.onUpPressed: list.currentList?.decrementCurrentIndex()
            Keys.onDownPressed: list.currentList?.incrementCurrentIndex()

            Keys.onEscapePressed: {
                if (quickLook.active)
                    quickLook.close();
                else
                    root.visibilities.launcher = false;
            }

            Keys.onPressed: event => {
                if (FileBrowser.isActive) {
                    if (event.key === Qt.Key_Tab) {
                        const completed = FileBrowser.tabComplete();
                        if (completed)
                            search.text = completed;
                        event.accepted = true;
                        return;
                    }

                    if (event.key === Qt.Key_Backspace && (event.modifiers & Qt.AltModifier)) {
                        FileBrowser.navigateUp();
                        search.text = FileBrowser.rawInput;
                        event.accepted = true;
                        return;
                    }

                    if (event.modifiers & Qt.ControlModifier) {
                        if (event.key === Qt.Key_G) {
                            FileBrowser.viewMode = FileBrowser.viewMode === "grid" ? "list" : "grid";
                            event.accepted = true;
                            return;
                        }
                        if (event.key === Qt.Key_I) {
                            FileBrowser.filterMode = FileBrowser.filterMode === "images" ? "all" : "images";
                            event.accepted = true;
                            return;
                        }
                        if (event.key === Qt.Key_C) {
                            const item = list.currentList?.currentItem;
                            if (!item)
                                return;
                            const entry = item.modelData;
                            if (event.modifiers & Qt.ShiftModifier) {
                                const mime = (entry.mimeType ?? "application/octet-stream").replace(/'/g, "'\\''");
                                const path = entry.path.replace(/'/g, "'\\''");
                                Quickshell.execDetached(["sh", "-c", "wl-copy --type '" + mime + "' < '" + path + "'"]);
                            } else {
                                Quickshell.execDetached(["wl-copy", entry.path]);
                            }
                            event.accepted = true;
                            return;
                        }
                        if (event.key === Qt.Key_T) {
                            FileBrowser.openTerminal(FileBrowser.currentDir);
                            root.visibilities.launcher = false;
                            event.accepted = true;
                            return;
                        }
                    }
                }

                if (!GlobalConfig.launcher.vimKeybinds)
                    return;

                if (event.modifiers & Qt.ControlModifier) {
                    if (event.key === Qt.Key_J || event.key === Qt.Key_N) {
                        list.currentList?.incrementCurrentIndex();
                        event.accepted = true;
                    } else if (event.key === Qt.Key_K || event.key === Qt.Key_P) {
                        list.currentList?.decrementCurrentIndex();
                        event.accepted = true;
                    }
                } else if (event.key === Qt.Key_Tab) {
                    list.currentList?.incrementCurrentIndex();
                    event.accepted = true;
                } else if (event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                    list.currentList?.decrementCurrentIndex();
                    event.accepted = true;
                }
            }

            Component.onCompleted: forceActiveFocus()

            Connections {
                function onLauncherChanged(): void {
                    if (!root.visibilities.launcher) {
                        search.text = "";
                        FileBrowser.reset();
                    }
                }

                function onSessionChanged(): void {
                    if (!root.visibilities.session)
                        search.forceActiveFocus();
                }

                target: root.visibilities
            }
        }

        MaterialIcon {
            id: clearIcon

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: root.padding

            width: search.text ? implicitWidth : implicitWidth / 2
            opacity: {
                if (!search.text)
                    return 0;
                if (mouse.pressed)
                    return 0.7;
                if (mouse.containsMouse)
                    return 0.8;
                return 1;
            }

            text: "close"
            color: Colours.palette.m3onSurfaceVariant

            MouseArea {
                id: mouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: search.text ? Qt.PointingHandCursor : undefined

                onClicked: search.text = ""
            }

            Behavior on width {
                Anim {
                    type: Anim.StandardSmall
                }
            }

            Behavior on opacity {
                Anim {
                    type: Anim.StandardSmall
                }
            }
        }
    }
}
