pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.modules.launcher.items
import qs.modules.launcher.services

GridView {
    id: root

    required property DrawerVisibilities visibilities

    readonly property int minCellWidth: 160 + Tokens.spacing.normal
    readonly property int columnsCount: Math.max(1, Math.floor(width / minCellWidth))

    cellWidth: width / columnsCount
    cellHeight: 140 + Tokens.spacing.normal

    clip: true

    model: ScriptModel {
        id: model

        values: (FileBrowser._dirVersion, FileBrowser.sortMode, FileBrowser.queryFiles(FileBrowser.searchFilter))
        onValuesChanged: root.currentIndex = 0
    }

    function incrementCurrentIndex() {
        moveCurrentIndexDown();
    }

    function decrementCurrentIndex() {
        moveCurrentIndexUp();
    }

    delegate: fileGridItemDelegate

    Component {
        id: fileGridItemDelegate

        FileGridItem {
            visibilities: root.visibilities
        }
    }

    StyledScrollBar.vertical: StyledScrollBar {
        flickable: root
    }

    add: Transition {
        Anim {
            properties: "opacity,scale"
            from: 0
            to: 1
            type: Anim.DefaultSpatial
        }
    }

    remove: Transition {
        Anim {
            property: "opacity"
            to: 0
        }
        Anim {
            property: "scale"
            to: 0.5
        }
    }

    displaced: Transition {
        Anim {
            properties: "opacity,scale"
            to: 1
            easing: Tokens.anim.standardDecel
        }
        Anim {
            properties: "x,y"
            type: Anim.DefaultSpatial
        }
    }
}
