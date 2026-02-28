// Workspaces widget driven by Niri IPC EventStream.
// Bullet style: focused = • at full opacity (purple), unfocused = • at 28% opacity.
// Scroll to switch workspace; click bullet to focus that workspace.

import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    implicitWidth: pillBg.width
    implicitHeight: 30

    property var workspaceModel: []

    // ── Niri IPC EventStream ─────────────────────────────────────────────────
    Socket {
        id: niriSocket
        path: Qt.environ("NIRI_SOCKET") || ""
        connected: true

        onConnectedChanged: {
            if (connected)
                niriSocket.write('{"EventStream":null}\n')
        }

        parser: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                if (!line.trim()) return
                try {
                    const msg = JSON.parse(line)
                    if (msg.Ok !== undefined) return   // handshake acknowledgement
                    if (msg.WorkspacesChanged) {
                        root.workspaceModel = msg.WorkspacesChanged.workspaces
                    } else if (msg.WorkspaceFocusChanged) {
                        // Update is_focused field in place without re-fetching
                        const id = msg.WorkspaceFocusChanged.id ?? -1
                        root.workspaceModel = root.workspaceModel.map(ws =>
                            Object.assign({}, ws, { is_focused: ws.id === id })
                        )
                    }
                } catch (_) {}
            }
        }
    }

    // ── Action processes (reused for all scroll events) ──────────────────────
    Process { id: focusUpProc;   command: ["niri", "msg", "action", "focus-workspace-up"]   }
    Process { id: focusDownProc; command: ["niri", "msg", "action", "focus-workspace-down"] }
    Process {
        id: focusWsProc
        property string targetIdx: "1"
        command: ["niri", "msg", "action", "focus-workspace", targetIdx]
    }

    // ── Pill background (width tracks bullet row) ────────────────────────────
    Rectangle {
        id: pillBg
        width:  wsRow.implicitWidth + 16
        height: 30
        color:  Qt.rgba(36/255, 41/255, 46/255, 0.7)
        bottomLeftRadius:  12
        bottomRightRadius: 12
    }

    // ── Scroll handler covers the full pill ──────────────────────────────────
    MouseArea {
        anchors.fill: parent
        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0) focusUpProc.running = true
            else                        focusDownProc.running = true
        }
    }

    // ── Bullet row ───────────────────────────────────────────────────────────
    Row {
        id: wsRow
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: root.workspaceModel

            Text {
                required property var modelData

                text:           "•"
                font.pixelSize: 18
                font.family:    "JetBrainsMono Nerd Font"
                color:          "#a12fff"
                opacity:        modelData.is_focused ? 1.0 : 0.28

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        focusWsProc.targetIdx = (modelData.idx).toString()
                        focusWsProc.running = true
                    }
                }
            }
        }
    }
}
