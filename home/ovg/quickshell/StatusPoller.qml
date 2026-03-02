// System stats singleton instantiated in shell.qml.
// Owns the single polling process for the whole bar.
// Polls system-stats.sh every 5 s; parses combined JSON output.
// Exposes cpu/mem percentages and warning state as reactive properties.

import Quickshell.Io
import QtQuick

QtObject {
    id: root

    // Public — bound into CpuMem and InfoBox by shell.qml
    property int    cpuPct:       0
    property int    memPct:       0
    property string warningText:  ""
    property string warningClass: "none"

    // ── Combined stats process ────────────────────────────────────────────────
    property var _scripts: Scripts { id: scripts }

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
        interval:         5000
        running:          true
        repeat:           true
        triggeredOnStart: true
        onTriggered: if (!root._proc.running) root._proc.running = true
    }
}
