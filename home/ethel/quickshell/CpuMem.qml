// CPU + Memory widget.
// cpuPct and memPct are bound from StatusPoller in shell.qml — no polling here.
// Bar colors shift primary→tertiary→error as load crosses 60% and 80%.
// Shadow: offset y=5, blur 0.7 — matches Niri window shadow config.

import QtQuick
import QtQuick.Effects

Item {
    id: root
    implicitWidth:  contentRow.implicitWidth + 36
    implicitHeight: 24

    property int cpuPct: 0
    property int memPct: 0

    function fillColor(pct) {
        if (pct >= 80) return Colors.errorFill
        if (pct >= 60) return Colors.barFill
        return Colors.accent
    }
    function trackColor(pct) {
        if (pct >= 80) return Colors.errorTrack
        if (pct >= 60) return Colors.barTrack
        return Colors.primaryTrack
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
        shadowColor:          Colors.shadowColor
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
            color: Colors.textColor
        }
        Item { width: 6; height: 16 }
        Rectangle {
            width: 80; height: 12; radius: 6
            anchors.verticalCenter: parent.verticalCenter
            color: root.trackColor(root.cpuPct)
            border.width: 1
            border.color: Colors.outline
            Behavior on color { ColorAnimation { duration: 300 } }

            Rectangle {
                id: cpuFill
                width:  Math.max(0, (parent.width - 2) * root.cpuPct / 100)
                height: parent.height - 2
                x: 1; y: 1
                radius: 5
                color: root.fillColor(root.cpuPct)
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 300 } }
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
            color: Colors.textColor
        }
        Item { width: 6; height: 16 }
        Rectangle {
            width: 80; height: 12; radius: 6
            anchors.verticalCenter: parent.verticalCenter
            color: root.trackColor(root.memPct)
            border.width: 1
            border.color: Colors.outline
            Behavior on color { ColorAnimation { duration: 300 } }

            Rectangle {
                id: memFill
                width:  Math.max(0, (parent.width - 2) * root.memPct / 100)
                height: parent.height - 2
                x: 1; y: 1
                radius: 5
                color: root.fillColor(root.memPct)
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 300 } }
            }
        }
    }
}
