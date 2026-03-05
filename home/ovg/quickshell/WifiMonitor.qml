// WiFi state singleton instantiated in shell.qml.
// Owns the single wifi-monitor process for the whole bar.
// Exposes wifiState as a reactive property bound into StatusIcons.
// Restarts the process with a 2-second backoff on exit to avoid
// tight restart loops if wifi-monitor crashes repeatedly.

import Quickshell.Io
import QtQuick

QtObject {
    id: root

    // Public — bound into StatusIcons by shell.qml
    property string wifiState: "off"

    // ── Scripts path registry ─────────────────────────────────────────────────
    property var _scripts: Scripts { id: scripts }

    // ── WiFi monitor: long-running process, emits JSON lines ─────────────────
    property var _proc: Process {
        running: true
        command: [scripts.wifiMonitor]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                const l = line.trim()
                if (!l) return
                try {
                    const d = JSON.parse(l)
                    root.wifiState = d.wifi || "off"
                } catch (_) {}
            }
        }
        // 2-second backoff instead of immediate restart to avoid tight loops
        // if wifi-monitor crashes (e.g., NetworkManager is temporarily absent).
        onExited: _restartTimer.restart()
    }

    // ── Backoff restart timer ─────────────────────────────────────────────────
    property var _restartTimer: Timer {
        interval: 2000
        repeat:   false
        onTriggered: if (!root._proc.running) root._proc.running = true
    }
}
