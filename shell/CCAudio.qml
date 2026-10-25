// Control center AUDIO (v2): the output volume as the lead (drag the bar), output + input device lists (click =
// default), the mic level, one thin level per app playing sound.
import QtQuick
import Quickshell.Services.Pipewire

Item {
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

    component GroupLabel: Text {
        topPadding: 14
        bottomPadding: 4
        color: Theme.dim
        font.family: Theme.mono
        font.pixelSize: 10
        font.letterSpacing: 3
    }

    width: 540
    implicitHeight: col.height + 52

    PwObjectTracker {
        objects: root.sinks.concat(root.sources).concat(root.streams)
    }

    Column {
        id: col
        x: 22
        y: 18
        width: parent.width - 44

        CCHero {
            value: Math.round(Math.min(1, root.sink?.audio?.volume ?? 0) * 100)
            unit: root.sink?.audio?.muted ? "MUTED" : "%"
            sub: ("OUTPUT  ·  " + root.nice(root.sink) + "  ·  " + root.streams.length + " PLAYING").toUpperCase()
            bar: Math.min(1, root.sink?.audio?.volume ?? 0)
            onBarSet: v => { if (root.sink?.audio) root.sink.audio.volume = v; }
        }

        GroupLabel { text: "OUTPUTS" }
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

        GroupLabel { text: "INPUTS" }
        CCLevel {
            compact: true
            label: "MIC"
            value: Math.min(1, root.source?.audio?.volume ?? 0)
            muted: root.source?.audio?.muted ?? false
            onChanged: v => { if (root.source?.audio) root.source.audio.volume = v; }
            onLabelClicked: if (root.source?.audio) root.source.audio.muted = !root.source.audio.muted
        }
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

        GroupLabel { text: "APPS"; visible: root.streams.length > 0 }
        Repeater {
            model: root.streams
            CCLevel {
                required property var modelData
                compact: true
                label: (root.appName(modelData) + ((modelData.properties || {})["media.name"] ? " · " + modelData.properties["media.name"] : "")).toUpperCase()
                value: Math.min(1, modelData.audio?.volume ?? 0)
                muted: modelData.audio?.muted ?? false
                onChanged: v => { if (modelData.audio) modelData.audio.volume = v; }
                onLabelClicked: if (modelData.audio) modelData.audio.muted = !modelData.audio.muted
            }
        }
    }
}
