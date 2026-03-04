// Clock widget. Updates every minute via SystemClock.
// Shadow: offset y=5, blur 0.7, #00000077 — matches Niri window shadow config.

import Quickshell
import QtQuick
import QtQuick.Effects

Item {
    id: root
    implicitWidth:  timeText.implicitWidth + 24
    implicitHeight: 24

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

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Text {
        id: timeText
        anchors.centerIn: parent
        text: {
            const h = clock.hours.toString().padStart(2, "0")
            const m = clock.minutes.toString().padStart(2, "0")
            return h + ":" + m
        }
        font.family:    "FiraMono Nerd Font"
        font.pixelSize: 16
        font.bold:      true
        color:          "#fafafa"
    }
}
