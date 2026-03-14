// Hyprland IPC singleton — instantiated by shell.qml when HYPRLAND_INSTANCE_SIGNATURE is set.
// Connects to the Hyprland event socket (socket2) and queries state via hyprctl (socket).
// Exposes the same interface as NiriIpc: workspaces, columns, languageText, languageClass.
// Reconnects automatically after 3 s if the socket drops.

import Quickshell.Io
import QtQuick

QtObject {
    id: root

    // Public — same interface as NiriIpc
    property var    workspaces:    []
    property var    columns:       []      // Simplified: no column tracking in Hyprland scrolling
    property string languageText:  "EN"
    property string languageClass: "en"

    // Internal
    property string _socketDir:  ""
    property int    _focusedWorkspaceId: -1

    // ── Read socket directory from environment ────────────────────────────────
    property var _getSocketDir: Process {
        command: ["sh", "-c", "printf '%s' \"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim()
                if (p && p.indexOf("hypr/") !== -1) {
                    root._socketDir = p
                    root._queryWorkspaces()
                    root._queryLayout()
                } else {
                    _socketRetryTimer.start()
                }
            }
        }
    }

    property var _socketRetryTimer: Timer {
        interval: 2000
        repeat:   false
        onTriggered: root._getSocketDir.running = true
    }

    Component.onCompleted: _getSocketDir.running = true

    // ── Event socket (socket2) ────────────────────────────────────────────────
    property var _eventSocket: Socket {
        path:      root._socketDir ? root._socketDir + "/.socket2.sock" : ""
        connected: root._socketDir !== ""

        onConnectedChanged: {
            if (!connected && root._socketDir !== "") {
                _reconnectTimer.restart()
            }
        }

        parser: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                if (!line.trim()) return
                const parts = line.split(">>")
                const event = parts[0]

                if (event === "workspace" || event === "createworkspace" ||
                    event === "destroyworkspace" || event === "moveworkspace") {
                    root._queryWorkspaces()
                } else if (event === "activelayout") {
                    // activelayout>>keyboard_name,layout_name
                    const data = parts[1] || ""
                    const lastComma = data.lastIndexOf(",")
                    if (lastComma !== -1) {
                        const layoutName = data.substring(lastComma + 1).toLowerCase()
                        root._applyLayout(layoutName)
                    }
                }
            }
        }
    }

    // ── Reconnect timer ───────────────────────────────────────────────────────
    property var _reconnectTimer: Timer {
        interval:  3000
        repeat:    false
        onTriggered: {
            const d = root._socketDir
            root._socketDir = ""
            root._socketDir = d
        }
    }

    // ── Query workspaces via hyprctl ──────────────────────────────────────────
    function _queryWorkspaces() {
        _workspaceQuery.running = true
    }

    property var _workspaceQuery: Process {
        command: [Scripts.hyprctl, "workspaces", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const ws = JSON.parse(text)
                    root._activeWorkspaceQuery.running = true
                    root._pendingWorkspaces = ws
                } catch (_) {}
            }
        }
    }

    property var _pendingWorkspaces: []

    property var _activeWorkspaceQuery: Process {
        command: [Scripts.hyprctl, "activeworkspace", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const active = JSON.parse(text)
                    const activeId = active.id
                    const ws = root._pendingWorkspaces
                    ws.sort((a, b) => a.id - b.id)
                    root.workspaces = ws.map(w => ({
                        id: w.id,
                        idx: w.id,
                        name: w.name || "",
                        is_focused: w.id === activeId
                    }))
                    root._focusedWorkspaceId = activeId
                } catch (_) {}
            }
        }
    }

    // ── Query keyboard layout ─────────────────────────────────────────────────
    function _queryLayout() {
        _layoutQuery.running = true
    }

    property var _layoutQuery: Process {
        command: [Scripts.hyprctl, "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const devices = JSON.parse(text)
                    const keyboards = devices.keyboards || []
                    for (let i = 0; i < keyboards.length; ++i) {
                        const kb = keyboards[i]
                        if (kb.main) {
                            root._applyLayout((kb.active_keymap || "").toLowerCase())
                            break
                        }
                    }
                    // Fallback: use first keyboard if no "main" flag
                    if (keyboards.length > 0 && !keyboards.some(k => k.main)) {
                        root._applyLayout((keyboards[0].active_keymap || "").toLowerCase())
                    }
                } catch (_) {}
            }
        }
    }

    // ── Layout helper ─────────────────────────────────────────────────────────
    function _applyLayout(name) {
        if (name.indexOf("russian") !== -1 || name === "ru") {
            root.languageText  = "RU"
            root.languageClass = "ru"
        } else {
            root.languageText  = "EN"
            root.languageClass = "en"
        }
    }
}
