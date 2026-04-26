pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.Models
import qs.components
import qs.components.controls
import qs.components.images
import qs.services
import qs.modules.launcher.services

Item {
    id: root

    required property var modelData
    required property StyledTextField search
    required property DrawerVisibilities visibilities

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    function humanSize(bytes): string {
        if (bytes < 1024)
            return bytes + " B";
        if (bytes < 1048576)
            return Math.round(bytes / 1024) + " KB";
        if (bytes < 1073741824)
            return (bytes / 1048576).toFixed(1) + " MB";
        return (bytes / 1073741824).toFixed(1) + " GB";
    }

    function detailText(): string {
        const file = root.modelData;
        if (!file)
            return "";
        if (file._type === "bookmark")
            return file._displayPath;
        if (file._type === "recent")
            return "Recent · " + file._displayPath;
        if (file.isDir)
            return "Directory";
        const parts = [];
        if (file.suffix)
            parts.push(file.suffix.toUpperCase());
        parts.push(root.humanSize(file.size));
        if (file.lastModified)
            parts.push(Qt.formatDateTime(file.lastModified, "dd.MM.yy hh:mm"));
        return parts.join(" · ");
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.RightButton
        onClicked: event => {
            if (root.modelData?._type)
                return;
            const pos = root.mapToGlobal(event.x, event.y);
            FileBrowser.contextMenuRequested(root.modelData, pos.x, pos.y);
        }
    }

    StateLayer {
        radius: Tokens.rounding.normal
        onClicked: {
            const entry = root.modelData;
            if (entry._type) {
                FileBrowser.navigateTo(entry.path);
                root.search.text = FileBrowser.rawInput;
            } else if (entry.isDir) {
                FileBrowser.navigateInto(entry.name);
                root.search.text = FileBrowser.rawInput;
            } else {
                FileBrowser.openFile(entry.path);
                root.visibilities.launcher = false;
            }
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.larger
        anchors.rightMargin: Tokens.padding.larger
        anchors.margins: Tokens.padding.smaller

        MaterialIcon {
            id: quickAccessIcon

            visible: root.modelData?._type === "bookmark" || root.modelData?._type === "recent"
            anchors.verticalCenter: parent.verticalCenter
            text: root.modelData?._type === "bookmark" ? "folder_special" : "schedule"
            font.pointSize: Tokens.font.size.extraLarge
            color: root.modelData?._type === "bookmark" ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
        }

        CachingIconImage {
            id: icon

            visible: !quickAccessIcon.visible
            implicitSize: parent.height * 0.8
            anchors.verticalCenter: parent.verticalCenter

            Component.onCompleted: {
                const file = root.modelData;
                if (!file || file._type)
                    return;
                if (file.isImage)
                    source = Qt.resolvedUrl(file.path);
                else if (file.isDir)
                    source = Quickshell.iconPath("inode-directory");
                else
                    source = Quickshell.iconPath(file.mimeType.replace("/", "-"), "application-x-zerosize");
            }
        }

        Item {
            anchors.left: (quickAccessIcon.visible ? quickAccessIcon : icon).right
            anchors.leftMargin: Tokens.spacing.normal
            anchors.right: chevron.left
            anchors.verticalCenter: parent.verticalCenter

            implicitHeight: name.implicitHeight + detail.implicitHeight

            StyledText {
                id: name

                text: root.modelData?.name ?? ""
                font.pointSize: Tokens.font.size.normal
                elide: Text.ElideRight
                width: parent.width
            }

            StyledText {
                id: detail

                text: root.detailText()
                font.pointSize: Tokens.font.size.small
                color: Colours.palette.m3outline

                elide: Text.ElideRight
                width: parent.width

                anchors.top: name.bottom
            }
        }

        MaterialIcon {
            id: chevron

            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right

            visible: root.modelData?.isDir ?? false
            text: "chevron_right"
            color: Colours.palette.m3outline
            font.pointSize: Tokens.font.size.large
        }
    }
}
