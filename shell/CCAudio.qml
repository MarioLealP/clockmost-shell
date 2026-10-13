// Control center AUDIO tab (no mock of its own - built from the panel parts): output and input device pickers
// with their levels, then one level row per application playing sound, with a live peak meter.
import QtQuick
import Quickshell.Services.Pipewire

CCTab {
    id: root

    readonly property var nodes: Pipewire.nodes.values
    readonly property var sinks: nodes.filter(n => n.type === PwNodeType.AudioSink)
    readonly property var sources: nodes.filter(n => n.type === PwNodeType.AudioSource)
    readonly property var streams: nodes.filter(n => n.type === PwNodeType.AudioOutStream)
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    function nice(n) {
        return n ? (n.description || n.nickname || n.name || "") : "";
    }
    function appName(n) {
        const p = n.properties || {};
        return p["application.name"] || n.description || n.name || "app";
    }

    code: "AU-02"

    PwObjectTracker {
        objects: root.sinks.concat(root.sources).concat(root.streams)
    }

    CCHeader {
        title: "AUDIO"
        sub: root.sinks.length + " OUT · " + root.sources.length + " IN · PIPEWIRE"
        count: String(root.streams.length)
        countLabel: "PLAYING"
    }

    Column {
        x: 18
        width: parent.width - 36
        spacing: 10
        bottomPadding: 14

        SectionLabel { text: "OUTPUT"; note: String(root.sinks.length).padStart(2, "0") }
        LevelRow {
            width: parent.width
            icon: root.sink?.audio?.muted ? Icons.volumeMuted : Icons.volume
            accent: Theme.cyan
            name: root.nice(root.sink).toUpperCase() || "NO DEVICE"
            value: Math.min(1, root.sink?.audio?.volume ?? 0)
            muted: root.sink?.audio?.muted ?? false
            onChanged: v => { if (root.sink?.audio) root.sink.audio.volume = v; }
            onIconClicked: if (root.sink?.audio) root.sink.audio.muted = !root.sink.audio.muted
        }
        Column {
            width: parent.width
            visible: root.sinks.length > 1
            Repeater {
                model: root.sinks
                DeviceRow {
                    required property var modelData
                    name: root.nice(modelData)
                    detail: (modelData.nickname || modelData.name || "").toUpperCase()
                    current: modelData === root.sink
                    onClicked: Pipewire.preferredDefaultAudioSink = modelData
                }
            }
        }

        SectionLabel { text: "INPUT"; note: String(root.sources.length).padStart(2, "0") }
        LevelRow {
            width: parent.width
            icon: Icons.mic
            accent: Theme.green
            name: root.nice(root.source).toUpperCase() || "NO DEVICE"
            value: Math.min(1, root.source?.audio?.volume ?? 0)
            muted: root.source?.audio?.muted ?? false
            onChanged: v => { if (root.source?.audio) root.source.audio.volume = v; }
            onIconClicked: if (root.source?.audio) root.source.audio.muted = !root.source.audio.muted
        }
        Column {
            width: parent.width
            visible: root.sources.length > 1
            Repeater {
                model: root.sources
                DeviceRow {
                    required property var modelData
                    name: root.nice(modelData)
                    detail: (modelData.nickname || modelData.name || "").toUpperCase()
                    current: modelData === root.source
                    onClicked: Pipewire.preferredDefaultAudioSource = modelData
                }
            }
        }

        SectionLabel { text: "APPLICATIONS"; note: String(root.streams.length).padStart(2, "0") }
        Repeater {
            model: root.streams
            Column {
                id: app
                required property var modelData
                width: parent.width
                spacing: 4
                LevelRow {
                    width: parent.width
                    icon: app.modelData.audio?.muted ? Icons.volumeMuted : Icons.volume
                    accent: AppColors.of(root.appName(app.modelData))
                    name: (root.appName(app.modelData) + ((app.modelData.properties || {})["media.name"] ? " · " + app.modelData.properties["media.name"] : "")).toUpperCase()
                    value: Math.min(1, app.modelData.audio?.volume ?? 0)
                    muted: app.modelData.audio?.muted ?? false
                    onChanged: v => { if (app.modelData.audio) app.modelData.audio.volume = v; }
                    onIconClicked: if (app.modelData.audio) app.modelData.audio.muted = !app.modelData.audio.muted
                }
                // live peak: what the app is actually putting out right now
                Item {
                    x: 38
                    width: parent.width - 38 - 52
                    height: 2
                    PwNodePeakMonitor {
                        id: peak
                        node: app.modelData
                    }
                    Rectangle { width: parent.width; height: 2; color: Qt.rgba(1, 1, 1, 0.05) }
                    Rectangle {
                        width: parent.width * Math.min(1, peak.peak)
                        height: 2
                        color: AppColors.of(root.appName(app.modelData))
                        Behavior on width { NumberAnimation { duration: 60 } }
                    }
                }
            }
        }
        Micro {
            visible: root.streams.length === 0
            text: "NO APPLICATION AUDIO"
        }
    }

}
