// The machine's live numbers in two rows (CPU GPU NET / RAM VRAM) at the bottom, right of the orange line, left of the hero (Mario
// 2026-10-26: that stretch was empty): CPU + GPU load and temperature, RAM, VRAM, network. Read every 2 s from /proc
// and /sys (hwmon found by name - the numbers move between boots); the bars ease to each new value.
import QtQuick
import Quickshell.Io

Rectangle {
    id: root

    property real cpu: 0 // 0..1
    property real gpu: 0
    property real cpuTemp: 0 // °C
    property real gpuTemp: 0
    property real ramUsed: 0 // bytes
    property real ramTotal: 1
    property real vramUsed: 0
    property real vramTotal: 1
    property real rx: 0 // bytes / s
    property real tx: 0
    property var prev: null // last sample: cpu jiffies + net bytes + time

    width: strip.width
    height: strip.height
    color: "transparent"

    function gb(b) { return (b / 1073741824).toFixed(1); }
    function rate(b) {
        return b >= 1048576 ? (b / 1048576).toFixed(1) + " MB/s" : b >= 1024 ? Math.round(b / 1024) + " KB/s" : Math.round(b) + " B/s";
    }

    Timer {
        interval: 2000
        repeat: true
        triggeredOnStart: true
        running: root.visible
        onTriggered: sample.running = true
    }
    Process {
        id: sample
        command: ["sh", "-c", "h() { for d in /sys/class/hwmon/hwmon*; do [ \"$(cat $d/name)\" = \"$1\" ] && cat $d/$2 && return; done; echo 0; }; "
            + "head -1 /proc/stat; awk '/^MemTotal|^MemAvailable/{print $2}' /proc/meminfo; "
            + "g=$(ls -d /sys/class/drm/card*/device 2>/dev/null | while read d; do [ -e $d/gpu_busy_percent ] && echo $d && break; done); "
            + "cat $g/gpu_busy_percent $g/mem_info_vram_used $g/mem_info_vram_total 2>/dev/null || printf '0\\n0\\n1\\n'; "
            + "h k10temp temp1_input; h amdgpu temp1_input; "
            + "awk '$1 ~ /^(enp|eth|wlp|wlan)/ {rx += $2; tx += $10} END {print rx, tx}' /proc/net/dev"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = text.trim().split("\n");
                if (l.length < 9) // stat, mem total, mem available, gpu busy, vram used, vram total, cpu °C, gpu °C, net
                    return;
                const j = l[0].trim().split(/\s+/).slice(1).map(Number);
                const total = j.reduce((a, b) => a + b, 0), idle = j[3] + (j[4] || 0);
                const [rxB, txB] = l[8].split(" ").map(Number);
                const now = Date.now();
                if (root.prev) {
                    const dt = Math.max(0.1, (now - root.prev.t) / 1000);
                    root.cpu = 1 - (idle - root.prev.idle) / Math.max(1, total - root.prev.total);
                    root.rx = Math.max(0, (rxB - root.prev.rx) / dt);
                    root.tx = Math.max(0, (txB - root.prev.tx) / dt);
                }
                root.prev = { total: total, idle: idle, rx: rxB, tx: txB, t: now };
                root.ramTotal = Number(l[1]) * 1024;
                root.ramUsed = root.ramTotal - Number(l[2]) * 1024;
                root.gpu = Number(l[3]) / 100;
                root.vramUsed = Number(l[4]);
                root.vramTotal = Math.max(1, Number(l[5]));
                root.cpuTemp = Number(l[6]) / 1000;
                root.gpuTemp = Number(l[7]) / 1000;
            }
        }
    }

    Grid {
        id: strip
        columns: 3
        columnSpacing: 24
        rowSpacing: 18
        Reading { width: 220; label: "CPU"; value: Math.round(root.cpu * 100); unit: "%"; note: Math.round(root.cpuTemp) + " °C"; level: root.cpu; hot: root.cpuTemp >= 85 }
        Reading { width: 220; label: "GPU"; value: Math.round(root.gpu * 100); unit: "%"; note: Math.round(root.gpuTemp) + " °C"; level: root.gpu; hot: root.gpuTemp >= 90 }
        // network: no bar, the two rates
        Item {
            width: 220
            height: 66
            Text { y: 4; text: "NET"; color: GroundTheme.ink2; font.family: GroundTheme.mono; font.pixelSize: 11; font.letterSpacing: 3 }
            Column {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 6
                spacing: 2
                Text { text: "↓ " + root.rate(root.rx); color: GroundTheme.ink; font.family: GroundTheme.mono; font.pixelSize: 13; font.letterSpacing: 1 }
                Text { text: "↑ " + root.rate(root.tx); color: GroundTheme.ink2; font.family: GroundTheme.mono; font.pixelSize: 13; font.letterSpacing: 1 }
            }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: GroundTheme.line }
        }
        Reading { width: 220; label: "RAM"; value: root.gb(root.ramUsed); unit: "GB"; note: "OF " + root.gb(root.ramTotal); level: root.ramUsed / root.ramTotal }
        Reading { width: 220; label: "VRAM"; value: root.gb(root.vramUsed); unit: "GB"; note: "OF " + root.gb(root.vramTotal); level: root.vramUsed / root.vramTotal }
    }
}
