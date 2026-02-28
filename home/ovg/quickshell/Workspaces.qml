// Workspaces widget driven by Niri IPC EventStream.
// Bullet style: focused = • at full opacity (purple), unfocused = • at 28% opacity.
// Scroll to switch workspace; click bullet to focus that workspace.
// Socket path is read from $NIRI_SOCKET at startup via a shell process,
// because Qt.environ() does not exist in QML.

import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    implicitWidth: pillBg.width
    implicitHeight: 24

    property var    workspaceModel: []
    property string socketPath:     ""

    // ── Read NIRI_SOCKET from the environment via shell ───────────────────────
    Process {
        id: getSocketPath
        command: ["sh", "-c", "printf '%s' \"$NIRI_SOCKET\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim()
                if (p) root.socketPath = p
            }
        }
    }
    Component.onCompleted: getSocketPath.running = true

    // ── Niri IPC EventStream ─────────────────────────────────────────────────
    Socket {
        id: niriSocket
        path:      root.socketPath
        connected: root.socketPath !== ""

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
                    if (msg.Ok !== undefined) return   // acknowledgement
                    if (msg.WorkspacesChanged) {
                        root.workspaceModel = msg.WorkspacesChanged.workspaces
                    } else if (msg.WorkspaceFocusChanged) {
                        const id = msg.WorkspaceFocusChanged.id ?? -1
                        root.workspaceModel = root.workspaceModel.map(ws =>
                            Object.assign({}, ws, { is_focused: ws.id === id })
                        )
                    }
                } catch (_) {}
            }
        }
    }

    // ── Action processes ─────────────────────────────────────────────────────
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
        height: 24
        color:  Qt.rgba(36/255, 41/255, 46/255, 0.7)
        bottomLeftRadius:  12
        bottomRightRadius: 12
    }

    // ── Scroll handler ───────────────────────────────────────────────────────
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
                font.pixelSize: 12
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
