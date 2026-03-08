// Columns widget driven by Niri IPC EventStream via NiriIpc in shell.qml.
// columnModel is bound from the parent — no socket logic here.
// Bullet style: same as Workspaces — focused column = full opacity, rest = 28%.
// No interaction — display only.
// Hidden when empty (no tiled windows on the active workspace).
// Shadow: offset y=5, blur 0.7 — matches Niri window shadow config.

import QtQuick
import QtQuick.Effects

Item {
    id: root
    implicitWidth: columnModel.length > 0 ? pillBg.width : 0
    implicitHeight: 24
    visible: columnModel.length > 0

    property var columnModel: []

    // ── Pill background (hidden — MultiEffect renders it with shadow) ─────────
    Rectangle {
        id: pillBg
        width:  colRow.implicitWidth + 24
        height: 24
        color:  Colors.pillBg
        bottomLeftRadius:  12
        bottomRightRadius: 12
        visible: false
    }

    MultiEffect {
        source:               pillBg
        anchors.fill:         pillBg
        autoPaddingEnabled:   true
        shadowEnabled:        true
        shadowColor:          Colors.shadowColor
        shadowBlur:           0.7
        shadowVerticalOffset: 5
        shadowHorizontalOffset: 0
    }

    // ── Bullet row ───────────────────────────────────────────────────────
    Row {
        id: colRow
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: root.columnModel

            Text {
                required property var modelData

                text:           "●"
                font.pixelSize: 14
                font.family:    "FiraMono Nerd Font"
                color:          Colors.accent
                opacity:        modelData.isFocused ? 1.0 : 0.28
            }
        }
    }
}
