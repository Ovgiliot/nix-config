// Workspaces widget driven by Niri IPC EventStream via NiriIpc in shell.qml.
// workspaceModel is bound from the parent — no socket logic here.
// Bullet style: ● focused = purple full opacity, unfocused = 28% opacity.
// Scroll to switch workspace; click bullet to focus that workspace.
// Shadow: offset y=5, blur 0.7, #00000077 — matches Niri window shadow config.

import Quickshell.Io
import QtQuick
import QtQuick.Effects

Item {
    id: root
    implicitWidth: pillBg.width
    implicitHeight: 24

    property var workspaceModel: []

    // ── Action processes ─────────────────────────────────────────────────────
    Process { id: focusUpProc;   command: ["niri", "msg", "action", "focus-workspace-up"]   }
    Process { id: focusDownProc; command: ["niri", "msg", "action", "focus-workspace-down"] }
    Process {
        id: focusWsProc
        property string targetIdx: "1"
        command: ["niri", "msg", "action", "focus-workspace", targetIdx]
    }

    // ── Pill background (hidden — MultiEffect renders it with shadow) ─────────
    Rectangle {
        id: pillBg
        width:  wsRow.implicitWidth + 16
        height: 24
        color:  Qt.rgba(36/255, 41/255, 46/255, 0.7)
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

                text:           "●"
                font.pixelSize: 14
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
