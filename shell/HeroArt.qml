// The hero's pictures: every image in ~/.config/clockmost/ground-art/ (jpg / png / webp), one picked at random every
// 10 minutes (never the one showing) - HeroSlices plays the halftone swap. Empty folder: the single
// ~/.config/clockmost/ground-art.jpg, no swaps. next() = swap now (IPC: ground art).
pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell

Singleton {
    id: root

    readonly property string folder: Quickshell.env("HOME") + "/.config/clockmost/ground-art"
    property var files: [] // file:// urls
    property int requests: 0
    property int markPokes: 0 // IPC ground marks: the X marks re-strike + focus pull now (preview)

    function next() {
        if (files.length > 1)
            requests++;
    }
    function pick(except) {
        const pool = files.filter(f => String(f) !== String(except));
        return pool.length ? pool[Math.floor(Math.random() * pool.length)] : (files[0] ?? GroundTheme.art);
    }

    FolderListModel {
        id: model
        folder: "file://" + root.folder
        nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.JPG", "*.PNG"]
        showDirs: false
        onStatusChanged: if (status === FolderListModel.Ready) root.rebuild()
        onCountChanged: root.rebuild()
    }
    function rebuild() {
        const out = [];
        for (let i = 0; i < model.count; i++)
            out.push(model.get(i, "fileUrl"));
        files = out;
    }

    Timer {
        interval: 600000
        repeat: true
        running: root.files.length > 1
        onTriggered: root.next()
    }
}
