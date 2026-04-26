pragma Singleton

import "../../../utils/scripts/fzf.js" as Fzf
import QtQuick
import Quickshell
import Caelestia
import Caelestia.Models
import qs.services
import qs.utils

Singleton {
    id: root

    property string rawInput
    property string filterMode: "all"
    property string viewMode: "list"
    property string sortMode: "name"

    readonly property bool isActive: rawInput.startsWith("/") || rawInput.startsWith("~/")
    readonly property string currentDir: internal.dirPath
    readonly property string searchFilter: internal.afterLastSlash
    readonly property bool showQuickAccess: rawInput === "/" || rawInput === "~/"

    signal fileActivated(var entry)
    signal contextMenuRequested(var entry, real screenX, real screenY)

    property var _cachedFinder: null
    property int _dirVersion: 0
    property var _recentDirs: []
    property int _recentVersion: 0

    function parseInput(text: string): void {
        rawInput = text;
    }

    function _shortenPath(p: string): string {
        const home = Paths.home;
        if (p.startsWith(home))
            return "~" + p.substring(home.length);
        return p;
    }

    function _makeQuickEntry(label: string, dirPath: string, type: string): var {
        return {
            name: label,
            path: dirPath.endsWith("/") ? dirPath.slice(0, -1) : dirPath,
            isDir: true,
            isImage: false,
            suffix: "",
            size: 0,
            mimeType: "inode/directory",
            lastModified: null,
            parentDir: dirPath.substring(0, dirPath.lastIndexOf("/")),
            _type: type,
            _displayPath: _shortenPath(dirPath.endsWith("/") ? dirPath.slice(0, -1) : dirPath)
        };
    }

    function quickAccessEntries(): list<var> {
        const home = Paths.home;
        const entries = [];
        const defaultPaths = [
            { label: "Home", path: home },
            { label: "Downloads", path: home + "/Downloads" },
            { label: "Documents", path: home + "/Documents" },
            { label: "Pictures", path: home + "/Pictures" },
            { label: "Videos", path: home + "/Videos" },
            { label: "Music", path: home + "/Music" },
        ];

        for (const bm of defaultPaths)
            entries.push(_makeQuickEntry(bm.label, bm.path, "bookmark"));

        const bookmarkPaths = new Set(defaultPaths.map(b => b.path));
        for (const dir of _recentDirs) {
            const clean = dir.endsWith("/") ? dir.slice(0, -1) : dir;
            if (bookmarkPaths.has(clean))
                continue;
            const parts = clean.split("/").filter(Boolean);
            entries.push(_makeQuickEntry(parts[parts.length - 1] || "/", clean, "recent"));
        }

        return entries;
    }

    function _trackRecent(dirPath: string): void {
        if (!dirPath || dirPath === "/" || dirPath === Paths.home + "/")
            return;
        const clean = dirPath.endsWith("/") ? dirPath.slice(0, -1) : dirPath;
        const filtered = _recentDirs.filter(d => d !== clean);
        filtered.unshift(clean);
        if (filtered.length > 15)
            filtered.length = 15;
        _recentDirs = filtered;
        _recentVersion++;
    }

    function _sortEntries(items: list<var>): list<var> {
        const mode = sortMode;
        if (mode === "name")
            return items;
        const dirs = items.filter(e => e.isDir);
        const files = items.filter(e => !e.isDir);
        if (mode === "size")
            files.sort((a, b) => b.size - a.size);
        else if (mode === "type")
            files.sort((a, b) => (a.suffix ?? "").localeCompare(b.suffix ?? ""));
        else if (mode === "date")
            files.sort((a, b) => (b.lastModified?.getTime?.() ?? 0) - (a.lastModified?.getTime?.() ?? 0));
        return [...dirs, ...files];
    }

    function queryFiles(filter: string): list<var> {
        const entries = dirModel.entries;
        if (!filter)
            return _sortEntries([...entries]);

        if (!_cachedFinder || _cachedFinder._src !== entries) {
            _cachedFinder = new Fzf.Finder([...entries], { selector: e => e.name });
            _cachedFinder._src = entries;
        }
        const results = _cachedFinder.find(filter).sort((a, b) => {
            if (a.score === b.score)
                return a.item.name.length - b.item.name.length;
            return b.score - a.score;
        }).map(r => r.item);
        return sortMode === "name" ? results : _sortEntries(results);
    }

    function tabComplete(): string {
        const entries = [...completionModel.entries];
        const partial = internal.afterLastSlash.toLowerCase();
        const matches = partial
            ? entries.filter(e => e.name.toLowerCase().startsWith(partial))
            : entries;

        if (matches.length === 0)
            return "";

        const rawDir = rawInput.substring(0, rawInput.lastIndexOf("/") + 1);

        if (matches.length === 1)
            return rawDir + matches[0].name + "/";

        let prefix = matches[0].name;
        for (let i = 1; i < matches.length; i++) {
            const name = matches[i].name;
            let j = 0;
            while (j < prefix.length && j < name.length && prefix[j].toLowerCase() === name[j].toLowerCase())
                j++;
            prefix = prefix.substring(0, j);
            if (!prefix)
                break;
        }

        if (prefix.length <= partial.length)
            return "";

        return rawDir + prefix;
    }

    function navigateInto(dirName: string): void {
        const raw = rawInput;
        const lastSlash = raw.lastIndexOf("/");
        rawInput = raw.substring(0, lastSlash + 1) + dirName + "/";
    }

    function navigateTo(dirPath: string): void {
        rawInput = _shortenPath(dirPath.endsWith("/") ? dirPath : dirPath + "/");
    }

    function navigateUp(): void {
        const raw = rawInput;
        if (raw === "/" || raw === "~/")
            return;
        const trimmed = raw.replace(/[^/]*\/?$/, "");
        if (trimmed)
            rawInput = trimmed;
    }

    function openFile(path: string): void {
        Quickshell.execDetached(["xdg-open", path]);
    }

    function openTerminal(dir: string): void {
        Quickshell.execDetached(["sh", "-c", 'cd "$1" && shift && exec "$@"', "_", dir, "app2unit", "--", ...Config.general.apps.terminal]);
    }

    function imageList(): list<var> {
        return queryFiles(searchFilter).filter(e => e.isImage);
    }

    function reset(): void {
        rawInput = "";
        filterMode = "all";
        viewMode = "list";
        sortMode = "name";
    }

    onFilterModeChanged: {
        if (filterMode === "images")
            viewMode = "grid";
    }

    onShowQuickAccessChanged: {
        if (showQuickAccess)
            viewMode = "list";
    }

    onCurrentDirChanged: {
        if (currentDir && !showQuickAccess)
            _trackRecent(currentDir);
    }

    QtObject {
        id: internal

        readonly property string expanded: {
            let input = root.rawInput;
            if (input.startsWith("~/"))
                input = Paths.home + input.substring(1);
            return input;
        }

        readonly property string afterLastSlash: {
            const raw = root.rawInput;
            const lastSlash = raw.lastIndexOf("/");
            if (lastSlash < 0)
                return raw;
            return raw.substring(lastSlash + 1);
        }

        readonly property string dirPath: {
            if (!root.isActive)
                return "";
            const path = expanded;
            const lastSlash = path.lastIndexOf("/");
            return path.substring(0, lastSlash + 1);
        }
    }

    FileSystemModel {
        id: dirModel

        path: root.currentDir
        recursive: false
        watchChanges: true
        filter: root.filterMode === "images" ? FileSystemModel.Images : FileSystemModel.NoFilter
        onEntriesChanged: { root._cachedFinder = null; root._dirVersion++; }
    }

    FileSystemModel {
        id: completionModel

        path: internal.dirPath
        recursive: false
        watchChanges: false
        filter: FileSystemModel.Dirs
    }
}
