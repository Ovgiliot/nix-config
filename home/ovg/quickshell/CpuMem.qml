// CPU + Memory widget.
// Polls cpu-mem.sh every 2 s; parses JSON {cpu, mem}.
// Pill background: standard dark. Bar tracks: opaque dark with 1px black border.
// Bar fills: green/amber/red per bar, 80 px wide, animated.
// Shadow: offset y=5, blur 0.7, #00000077 — matches Niri window shadow config.

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Effects

Item {
    id: root
    implicitWidth:  contentRow.implicitWidth + 24
    implicitHeight: 24

    property int cpuPct: 0
    property int memPct: 0

    readonly property color cpuFillColor: cpuPct >= 75
        ? Qt.rgba(248/255,  81/255,  73/255, 0.9)
        : cpuPct >= 40
            ? Qt.rgba(210/255, 153/255,  34/255, 0.9)
            : Qt.rgba( 63/255, 185/255,  80/255, 0.9)

    readonly property color memFillColor: memPct >= 75
        ? Qt.rgba(248/255,  81/255,  73/255, 0.9)
        : memPct >= 40
            ? Qt.rgba(210/255, 153/255,  34/255, 0.9)
            : Qt.rgba( 63/255, 185/255,  80/255, 0.9)

    // ── Pill background (hidden — MultiEffect renders it with shadow) ─────────
    Rectangle {
        id: pillBg
        anchors.fill: parent
        color: Qt.rgba(36/255, 41/255, 46/255, 0.7)
        bottomLeftRadius:  12
        bottomRightRadius: 12
        visible: false
    }

    MultiEffect {
        source:               pillBg
        anchors.fill:         pillBg
        autoPaddingEnabled:   true
        shadowEnabled:        true
        shadowColor:          "#77000000"
        shadowBlur:           0.7
        shadowVerticalOffset: 5
        shadowHorizontalOffset: 0
    }

    // ── Content row ───────────────────────────────────────────────────────────
    // All items are height 16; anchors.centerIn gives 4px top/bottom padding.
    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 0

        // ── CPU ───────────────────────────────────────────────────────────────
        Text {
            height: 16
            verticalAlignment: Text.AlignVCenter
            text: "CPU"
            font.family:    "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            color: "#fafafa"
        }
        Item { width: 6; height: 16 }
        Rectangle {
            width: 80; height: 16; radius: 2
            color: Qt.rgba(36/255, 41/255, 46/255, 1.0)
            border.width: 1
            border.color: "#000000"

            Rectangle {
                id: cpuFill
                width:  Math.max(0, (parent.width - 2) * root.cpuPct / 100)
                height: parent.height - 2
                x: 1; y: 1
                radius: 2
                color:  root.cpuFillColor
                Behavior on color { ColorAnimation { duration: 400 } }
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            }
        }

        Item { width: 12; height: 16 }   // section gap

        // ── MEM ───────────────────────────────────────────────────────────────
        Text {
            height: 16
            verticalAlignment: Text.AlignVCenter
            text: "MEM"
            font.family:    "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            color: "#fafafa"
        }
        Item { width: 6; height: 16 }
        Rectangle {
            width: 80; height: 16; radius: 2
            color: Qt.rgba(36/255, 41/255, 46/255, 1.0)
            border.width: 1
            border.color: "#000000"

            Rectangle {
                id: memFill
                width:  Math.max(0, (parent.width - 2) * root.memPct / 100)
                height: parent.height - 2
                x: 1; y: 1
                radius: 2
                color:  root.memFillColor
                Behavior on color { ColorAnimation { duration: 400 } }
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            }
        }
    }

    // ── Script poller ─────────────────────────────────────────────────────────
    Scripts { id: scripts }

    Process {
        id: cpuMemProc
        command: [scripts.cpuMem]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text.trim())
                    root.cpuPct = Math.min(100, Math.max(0, d.cpu ?? 0))
                    root.memPct = Math.min(100, Math.max(0, d.mem ?? 0))
                } catch (_) {}
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!cpuMemProc.running) cpuMemProc.running = true
    }
}
