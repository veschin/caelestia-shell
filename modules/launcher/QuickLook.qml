pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.components.images
import qs.services
import qs.modules.launcher.services

FocusScope {
    id: root

    property bool active: false
    property list<var> images: []
    property int currentIndex: 0
    required property StyledTextField searchField
    required property DrawerVisibilities visibilities

    visible: active
    focus: active
    z: 10

    opacity: active ? 1 : 0
    scale: active ? 1 : 0.95

    function open(imageList: list<var>, startIndex: int): void {
        if (imageList.length === 0)
            return;
        images = imageList;
        currentIndex = startIndex;
        active = true;
        forceActiveFocus();
    }

    function close(): void {
        active = false;
        searchField.forceActiveFocus();
    }

    Behavior on opacity {
        Anim { type: Anim.StandardSmall }
    }

    Behavior on scale {
        Anim { type: Anim.StandardSmall }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(
            Colours.palette.m3surface.r,
            Colours.palette.m3surface.g,
            Colours.palette.m3surface.b,
            0.92
        )

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    CachingImage {
        id: preview

        anchors.fill: parent
        anchors.margins: Tokens.padding.large
        anchors.bottomMargin: infoBar.height + Tokens.padding.large

        path: root.images[root.currentIndex]?.path ?? ""
        fillMode: Image.PreserveAspectFit
        cache: true
        smooth: true

        opacity: status === Image.Ready ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutQuad
            }
        }
    }

    Column {
        id: infoBar

        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: Tokens.padding.normal

        spacing: Tokens.spacing.small

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.images[root.currentIndex]?.name ?? ""
            font.pointSize: Tokens.font.size.normal
            font.weight: 500
            color: Colours.palette.m3onSurface
        }

        StyledText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.images.length > 0 ? `${root.currentIndex + 1} / ${root.images.length}` : ""
            font.pointSize: Tokens.font.size.small
            color: Colours.palette.m3outline
        }
    }

    Keys.onLeftPressed: {
        if (currentIndex > 0)
            currentIndex--;
    }

    Keys.onRightPressed: {
        if (currentIndex < images.length - 1)
            currentIndex++;
    }

    Keys.onEscapePressed: close()

    Keys.onReturnPressed: {
        if (images.length > 0) {
            FileBrowser.openFile(images[currentIndex].path);
            visibilities.launcher = false;
        }
    }

    Keys.onPressed: event => {
        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_C) {
            if (root.images.length > 0)
                Quickshell.execDetached(["wl-copy", root.images[root.currentIndex].path]);
            event.accepted = true;
        }
    }
}
