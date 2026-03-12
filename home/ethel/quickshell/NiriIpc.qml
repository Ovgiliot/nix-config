// Niri IPC singleton (non-pragma) instantiated in shell.qml.
// Owns the single EventStream socket for the whole bar.
// Exposes workspaces, columns, and keyboard layout as reactive properties.
// Reconnects automatically after 3 s if the socket drops.
// Retries socket path resolution every 2 s if NIRI_SOCKET is empty at startup.

import Quickshell.Io
import QtQuick

QtObject {
    id: root

    // Public — bound into child widgets by shell.qml
    property var    workspaces:    []
    property var    columns:       []      // [{ columnIndex, isFocused }] for active workspace
    property string languageText:  "EN"
    property string languageClass: "en"

    // Internal
    property string _socketPath:  ""
    property var    _layoutNames: []
    property var    _windows:     ({})     // windowId → window object
    property int    _focusedWindowId: -1

    // ── Read NIRI_SOCKET path from environment via shell ──────────────────────
    property var _getSocketPath: Process {
        command: ["sh", "-c", "printf '%s' \"$NIRI_SOCKET\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim()
                if (p) {
                    root._socketPath = p
                } else {
                    // NIRI_SOCKET not yet in environment (bar started before
                    // niri fully initialised) — retry after 2 s.
                    _socketRetryTimer.start()
                }
            }
        }
    }

    // ── Retry timer for initial socket path resolution ────────────────────────
    property var _socketRetryTimer: Timer {
        interval: 2000
        repeat:   false
        onTriggered: root._getSocketPath.running = true
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
                        const ws = msg.WorkspacesChanged.workspaces
                        ws.sort((a, b) => a.idx - b.idx)
                        root.workspaces = ws
                        root._rebuildColumns()

                    } else if (msg.WorkspaceActivated) {
                        if (msg.WorkspaceActivated.focused) {
                            const id = msg.WorkspaceActivated.id
                            root.workspaces = root.workspaces.map(ws =>
                                Object.assign({}, ws, { is_focused: ws.id === id })
                            )
                            root._rebuildColumns()
                        }

                    } else if (msg.WindowOpenedOrChanged) {
                        const w = msg.WindowOpenedOrChanged.window
                        const wins = root._windows
                        wins[w.id] = w
                        root._windows = wins
                        if (w.is_focused) root._focusedWindowId = w.id
                        root._rebuildColumns()

                    } else if (msg.WindowClosed) {
                        const wid = msg.WindowClosed.id
                        const wins = root._windows
                        delete wins[wid]
                        root._windows = wins
                        if (root._focusedWindowId === wid) root._focusedWindowId = -1
                        root._rebuildColumns()

                    } else if (msg.WindowFocusChanged) {
                        root._focusedWindowId = msg.WindowFocusChanged.id ?? -1
                        root._rebuildColumns()

                    } else if (msg.WindowsChanged) {
                        const newWins = {}
                        const list = msg.WindowsChanged.windows
                        for (let i = 0; i < list.length; ++i) {
                            newWins[list[i].id] = list[i]
                        }
                        root._windows = newWins
                        root._rebuildColumns()

                    } else if (msg.WindowLayoutsChanged) {
                        const changes = msg.WindowLayoutsChanged.changes
                        const wins = root._windows
                        for (let i = 0; i < changes.length; ++i) {
                            const wid = changes[i][0]
                            const layout = changes[i][1]
                            if (wins[wid]) wins[wid].layout = layout
                        }
                        root._windows = wins
                        root._rebuildColumns()

                    } else if (msg.KeyboardLayoutsChanged) {
                        const kl = msg.KeyboardLayoutsChanged.keyboard_layouts
                        root._layoutNames = kl.names || []
                        root._applyLayout(kl.current_idx ?? 0)

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

    // ── Column rebuild ──────────────────────────────────────────────────────
    // Derives the public `columns` array from the internal _windows map.
    // Groups tiled windows on the focused workspace by column index.
    function _rebuildColumns() {
        // Find the focused workspace id
        let focusedWsId = -1
        for (let i = 0; i < root.workspaces.length; ++i) {
            if (root.workspaces[i].is_focused) {
                focusedWsId = root.workspaces[i].id
                break
            }
        }
        if (focusedWsId === -1) { root.columns = []; return }

        // Collect unique column indices for tiled windows on the focused workspace
        const colSet = {}
        const wins = root._windows
        const keys = Object.keys(wins)
        for (let i = 0; i < keys.length; ++i) {
            const w = wins[keys[i]]
            if (w.workspace_id !== focusedWsId) continue
            const pos = w.layout && w.layout.pos_in_scrolling_layout
            if (!pos) continue                   // floating window — skip
            const colIdx = pos[0]
            if (colSet[colIdx] === undefined) {
                colSet[colIdx] = false            // not focused yet
            }
            if (w.id === root._focusedWindowId) {
                colSet[colIdx] = true
            }
        }

        // Sort by column index and build the public array
        const sorted = Object.keys(colSet).map(Number).sort((a, b) => a - b)
        root.columns = sorted.map(ci => ({ columnIndex: ci, isFocused: colSet[ci] }))
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
