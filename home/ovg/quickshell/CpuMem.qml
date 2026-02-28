// CPU + Memory widget.
// Polls cpu-mem.sh every 2 s; parses JSON {cpu, mem}.
// Pill background: standard dark (same as clock).
// Bar tracks: same color, fully opaque. Bar fills: green/amber/red per bar,
// animated independently. Bars are 16 px tall, centered in the 24 px pill.

import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    implicitWidth:  contentRow.implicitWidth + 24
    implicitHeight: 24

    property int cpuPct: 0
    property int memPct: 0

    // Per-bar fill colours — change when the bar's own load crosses thresholds
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

    // Pill background — same color as clock, semi-transparent
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(36/255, 41/255, 46/255, 0.7)
        bottomLeftRadius:  12
        bottomRightRadius: 12
    }

    // Content row — all items are height 16 so the row is exactly 16 px,
    // which anchors.centerIn centers at y=4 inside the 24 px pill.
    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 0

        // ── CPU ──────────────────────────────────────────────────────────────
        Text {
            height: 16
            verticalAlignment: Text.AlignVCenter
            text: "CPU"
            font.family:    "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            color: "#fafafa"
        }
        Item { width: 6; height: 16 }
        Rectangle {
            width: 40; height: 16; radius: 2
            color: Qt.rgba(36/255, 41/255, 46/255, 1.0)  // opaque track

            Rectangle {
                id: cpuFill
                width:  Math.max(0, parent.width * root.cpuPct / 100)
                height: parent.height
                radius: 2
                color:  root.cpuFillColor
                Behavior on color { ColorAnimation { duration: 400 } }
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            }
        }
        Item { width: 6; height: 16 }
        Text {
            width: 40; height: 16
            verticalAlignment:   Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: root.cpuPct + "%"
            font.family:    "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            color: "#fafafa"
        }

        Item { width: 12; height: 16 }   // section gap

        // ── MEM ──────────────────────────────────────────────────────────────
        Text {
            height: 16
            verticalAlignment: Text.AlignVCenter
            text: "MEM"
            font.family:    "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            color: "#fafafa"
        }
        Item { width: 6; height: 16 }
        Rectangle {
            width: 40; height: 16; radius: 2
            color: Qt.rgba(36/255, 41/255, 46/255, 1.0)

            Rectangle {
                id: memFill
                width:  Math.max(0, parent.width * root.memPct / 100)
                height: parent.height
                radius: 2
                color:  root.memFillColor
                Behavior on color { ColorAnimation { duration: 400 } }
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            }
        }
        Item { width: 6; height: 16 }
        Text {
            width: 40; height: 16
            verticalAlignment:   Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            text: root.memPct + "%"
            font.family:    "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            color: "#fafafa"
        }
    }

    // Script poller
    Process {
        id: cpuMemProc
        command: ["/home/ovg/.config/waybar/scripts/cpu-mem.sh"]
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
