// CPU + Memory widget.
// cpuPct and memPct are bound from StatusPoller in shell.qml — no polling here.
// Pill background: standard dark. Bar tracks: opaque dark with 1px black border.
// Bar fills: green/amber/red per bar, 80 px wide, animated.
// Shadow: offset y=5, blur 0.8, #00000077 — matches Niri window shadow config.

import QtQuick
import QtQuick.Effects

Item {
    id: root
    implicitWidth:  contentRow.implicitWidth + 24
    implicitHeight: 24

    property int cpuPct: 0
    property int memPct: 0

    function barColor(pct) {
        if (pct >= 75) return Colors.barRed
        if (pct >= 40) return Colors.barAmber
        return             Colors.barGreen
    }

    // ── Pill background (hidden — MultiEffect renders it with shadow) ─────────
    Rectangle {
        id: pillBg
        anchors.fill: parent
        color: Colors.pillBg
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

    // ── Content row ───────────────────────────────────────────────────────────
    // All items are height 16; anchors.centerIn gives 4px top/bottom padding.
    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 0

        // ── CPU ───────────────────────────────────────────────────────────────
        Text {
            height: 16
            verticalAlignment: Text.AlignVCenter
            text: "CPU"
            font.family:    "FiraMono Nerd Font"
            font.pixelSize: 14
            color: "#fafafa"
        }
        Item { width: 6; height: 16 }
        Rectangle {
            width: 80; height: 16; radius: 2
            color: Colors.barTrack
            border.width: 1
            border.color: "#000000"

            Rectangle {
                id: cpuFill
                width:  Math.max(0, (parent.width - 2) * root.cpuPct / 100)
                height: parent.height - 2
                x: 1; y: 1
                radius: 2
                color:  root.barColor(root.cpuPct)
                Behavior on color { ColorAnimation { duration: 400 } }
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            }
        }

        Item { width: 12; height: 16 }   // section gap

        // ── MEM ───────────────────────────────────────────────────────────────
        Text {
            height: 16
            verticalAlignment: Text.AlignVCenter
            text: "MEM"
            font.family:    "FiraMono Nerd Font"
            font.pixelSize: 14
            color: "#fafafa"
        }
        Item { width: 6; height: 16 }
        Rectangle {
            width: 80; height: 16; radius: 2
            color: Colors.barTrack
            border.width: 1
            border.color: "#000000"

            Rectangle {
                id: memFill
                width:  Math.max(0, (parent.width - 2) * root.memPct / 100)
                height: parent.height - 2
                x: 1; y: 1
                radius: 2
                color:  root.barColor(root.memPct)
                Behavior on color { ColorAnimation { duration: 400 } }
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            }
        }
    }
}
