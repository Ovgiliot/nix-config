// Keyboard language widget. Driven by NiriIpc in shell.qml — no polling here.
// Background transitions between gray (EN) and blue (RU).
// Text is bare "EN" / "RU" — no leading icon — ensuring clean centering.
// Shadow: offset y=5, blur 0.7, #00000077 — matches Niri window shadow config.

import QtQuick
import QtQuick.Effects

Item {
    id: root
    implicitWidth:  langLabel.implicitWidth + 24
    implicitHeight: 24

    property string langText:  "EN"
    property string langClass: "en"

    // ── Pill background (hidden — MultiEffect renders it with shadow) ─────────
    Rectangle {
        id: pillBg
        anchors.fill: parent
        color: root.langClass === "ru" ? Colors.langRu : Colors.pillBg
        bottomLeftRadius:  12
        bottomRightRadius: 12
        visible: false
        Behavior on color { ColorAnimation { duration: 300 } }
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

    Text {
        id: langLabel
        anchors.centerIn: parent
        text:           root.langText
        font.family:    "FiraMono Nerd Font"
        font.pixelSize: 14
        font.bold:      true
        color:          "#fafafa"
    }
}
