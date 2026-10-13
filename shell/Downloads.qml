// ~/Downloads for the dock's downloads stack: files from the last 24h, and whether something is still downloading
// (a browser's .part / .crdownload file). Browsers don't publish the total size, so progress is indeterminate.
pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell

Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/Downloads"
    property int recent: 0
    property bool active: false

    function scan() {
        const now = Date.now();
        let n = 0, part = false;
        for (let i = 0; i < folder.count; i++) {
            const name = folder.get(i, "fileName");
            if (/\.(part|crdownload)$/.test(name))
                part = true;
            else if (now - folder.get(i, "fileModified").getTime() < 24 * 3600 * 1000)
                n++;
        }
        recent = n;
        active = part;
    }
    function open() {
        Quickshell.execDetached(["xdg-open", dir]);
    }

    FolderListModel {
        id: folder
        folder: "file://" + root.dir
        showDirs: false
        showHidden: false
        onCountChanged: root.scan()
        onStatusChanged: if (status === FolderListModel.Ready) root.scan()
    }
    // "last 24h" ages out without a folder change
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: root.scan()
    }
}
