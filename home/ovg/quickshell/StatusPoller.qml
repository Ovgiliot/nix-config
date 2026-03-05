// System stats singleton instantiated in shell.qml.
// Owns the single stats polling process and the power-profile poll for the bar.
//
// Stats process: polls system-stats.sh every ~1.3 s (1 s timer + 0.3 s CPU
// sample inside the script). The guard prevents overlapping runs.
//
// Power poll: polls powerprofilesctl every 5 s (power profile changes rarely).
//
// Exposes cpu/mem percentages, warning state, and power profile as reactive
// properties bound into CpuMem, InfoBox, and StatusIcons by shell.qml.

import Quickshell.Io
import QtQuick

QtObject {
    id: root

    // Public — bound into CpuMem, InfoBox, and StatusIcons by shell.qml
    property int    cpuPct:       0
    property int    memPct:       0
    property string warningText:  ""
    property string warningClass: "none"
    property string powerState:   "balanced"

    // ── Scripts path registry ─────────────────────────────────────────────────
    property var _scripts: Scripts { id: scripts }

    // ── Combined stats process ────────────────────────────────────────────────
    property var _proc: Process {
        command: [scripts.status]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text.trim())
                    root.cpuPct       = Math.min(100, Math.max(0, d.cpu          ?? 0))
                    root.memPct       = Math.min(100, Math.max(0, d.mem          ?? 0))
                    root.warningText  = d.warning_text  || ""
                    root.warningClass = d.warning_class || "none"
                } catch (_) {}
            }
        }
    }

    property var _timer: Timer {
        interval:         1000
        running:          true
        repeat:           true
        triggeredOnStart: true
        onTriggered: if (!root._proc.running) root._proc.running = true
    }

    // ── Power profile: one-shot poll every 5 s ────────────────────────────────
    property var _powerProc: Process {
        command: [scripts.getPower]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                const l = line.trim()
                if (l) root.powerState = l
            }
        }
    }

    property var _powerTimer: Timer {
        interval:         5000
        running:          true
        repeat:           true
        triggeredOnStart: true
        onTriggered: if (!root._powerProc.running) root._powerProc.running = true
    }
}
