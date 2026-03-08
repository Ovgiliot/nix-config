// Keyboard language widget. Driven by NiriIpc in shell.qml — no polling here.
// Shadow: offset y=5, blur 0.7, #00000077 — matches Niri window shadow config.

import QtQuick
import QtQuick.Effects

Item {
    id: root
    implicitWidth:  langLabel.implicitWidth + 48
    implicitHeight: 24

    property string langText:  "EN"
    property string langClass: "en"

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

    Text {
        id: langLabel
        anchors.centerIn: parent
        text:           root.langText
        font.family:    "FiraMono Nerd Font"
        font.pixelSize: 14
        font.bold:      true
        color:          Colors.textColor
    }
}
