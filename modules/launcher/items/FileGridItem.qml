pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import Caelestia.Models
import qs.components
import qs.components.images
import qs.services
import qs.modules.launcher.services

Item {
    id: root

    required property var modelData
    required property DrawerVisibilities visibilities

    readonly property real itemMargin: Tokens.spacing.normal / 2
    readonly property real itemRadius: Tokens.rounding.normal

    width: GridView.view?.cellWidth ?? 160
    height: GridView.view?.cellHeight ?? 140

    MouseArea {
        anchors.fill: parent
        anchors.margins: root.itemMargin
        acceptedButtons: Qt.RightButton
        onClicked: event => {
            const pos = root.mapToGlobal(event.x, event.y);
            FileBrowser.contextMenuRequested(root.modelData, pos.x, pos.y);
        }
    }

    StateLayer {
        anchors.fill: parent
        anchors.leftMargin: root.itemMargin
        anchors.rightMargin: root.itemMargin
        anchors.topMargin: root.itemMargin
        anchors.bottomMargin: root.itemMargin
        radius: root.itemRadius

        onClicked: {
            const entry = root.modelData;
            if (entry.isDir || entry.isImage) {
                FileBrowser.fileActivated(entry);
            } else {
                FileBrowser.openFile(entry.path);
                root.visibilities.launcher = false;
            }
        }
    }

    StyledClippingRect {
        id: imageContainer

        anchors.fill: parent
        anchors.leftMargin: root.itemMargin
        anchors.rightMargin: root.itemMargin
        anchors.topMargin: root.itemMargin
        anchors.bottomMargin: root.itemMargin
        color: Colours.tPalette.m3surfaceContainer
        radius: root.itemRadius
        antialiasing: true
        layer.enabled: true
        layer.smooth: true

        CachingImage {
            id: cachingImage

            visible: root.modelData?.isImage ?? false
            path: (root.modelData?.isImage ?? false) ? root.modelData.path : ""
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            cache: true
            antialiasing: true
            smooth: true
            sourceSize: Qt.size(parent.width, parent.height)

            opacity: status === Image.Ready ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 500
                    easing.type: Easing.OutQuad
                }
            }
        }

        CachingIconImage {
            id: iconFallback

            visible: !(root.modelData?.isImage ?? false)
            anchors.centerIn: parent
            implicitSize: parent.height * 0.4

            Component.onCompleted: {
                const file = root.modelData;
                if (!file || file.isImage)
                    return;
                if (file.isDir)
                    source = Quickshell.iconPath("inode-directory");
                else
                    source = Quickshell.iconPath(file.mimeType.replace("/", "-"), "application-x-zerosize");
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom

            implicitHeight: filenameText.implicitHeight + Tokens.padding.normal * 1.5

            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.4; color: Qt.rgba(0, 0, 0, 0.3) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.6) }
            }

            visible: root.modelData?.isImage ?? false
        }
    }

    StyledText {
        id: filenameText

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: Tokens.padding.normal + root.itemMargin
        anchors.rightMargin: Tokens.padding.normal + root.itemMargin
        anchors.bottomMargin: Tokens.padding.small + root.itemMargin

        text: root.modelData?.name ?? ""
        font.pointSize: Tokens.font.size.smaller
        font.weight: 500
        color: (root.modelData?.isImage ?? false) ? "white" : Colours.palette.m3onSurface
        elide: Text.ElideMiddle
        maximumLineCount: 1
        horizontalAlignment: Text.AlignHCenter
    }
}
