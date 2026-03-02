// Niri IPC singleton (non-pragma) instantiated in shell.qml.
// Owns the single EventStream socket for the whole bar.
// Exposes workspaces and keyboard layout as reactive properties.
// Reconnects automatically after 3 s if the socket drops.

import Quickshell.Io
import QtQuick

QtObject {
    id: root

    // Public — bound into child widgets by shell.qml
    property var    workspaces:    []
    property string languageText:  "EN"
    property string languageClass: "en"

    // Internal
    property string _socketPath:  ""
    property var    _layoutNames: []

    // ── Read NIRI_SOCKET path from environment via shell ──────────────────────
    property var _getSocketPath: Process {
        command: ["sh", "-c", "printf '%s' \"$NIRI_SOCKET\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim()
                if (p) root._socketPath = p
            }
        }
    }

    Component.onCompleted: _getSocketPath.running = true

    // ── Niri IPC EventStream socket ───────────────────────────────────────────
    property var _socket: Socket {
        path:      root._socketPath
        connected: root._socketPath !== ""

        onConnectedChanged: {
            if (connected) {
                _socket.write('{"EventStream":null}\n')
            } else {
                // Socket dropped — schedule reconnect
                _reconnectTimer.restart()
            }
        }

        parser: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                if (!line.trim()) return
                try {
                    const msg = JSON.parse(line)
                    if (msg.Ok !== undefined) return   // acknowledgement

                    if (msg.WorkspacesChanged) {
                        root.workspaces = msg.WorkspacesChanged.workspaces

                    } else if (msg.WorkspaceActivated) {
                        if (msg.WorkspaceActivated.focused) {
                            const id = msg.WorkspaceActivated.id
                            root.workspaces = root.workspaces.map(ws =>
                                Object.assign({}, ws, { is_focused: ws.id === id })
                            )
                        }

                    } else if (msg.KeyboardLayoutsChanged) {
                        const kl = msg.KeyboardLayoutsChanged.keyboard_layouts
                        root._layoutNames = kl.names || []
                        root._applyLayout(kl.current_idx || 0)

                    } else if (msg.KeyboardLayoutSwitched) {
                        root._applyLayout(msg.KeyboardLayoutSwitched.idx)
                    }
                } catch (_) {}
            }
        }
    }

    // ── Reconnect timer (single-shot, 3 s) ────────────────────────────────────
    property var _reconnectTimer: Timer {
        interval:  3000
        repeat:    false
        onTriggered: {
            // Re-trigger connection by toggling socketPath
            const p = root._socketPath
            root._socketPath = ""
            root._socketPath = p
        }
    }

    // ── Layout helper ─────────────────────────────────────────────────────────
    function _applyLayout(idx) {
        const names = root._layoutNames
        if (!names || names.length === 0) return
        const name = (names[idx] || "").toLowerCase()
        if (name.indexOf("russian") !== -1 || name === "ru") {
            root.languageText  = "RU"
            root.languageClass = "ru"
        } else {
            root.languageText  = "EN"
            root.languageClass = "en"
        }
    }
}
