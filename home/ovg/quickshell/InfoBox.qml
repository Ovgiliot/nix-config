// Info-box widget.
// warningText and warningClass are bound from StatusPoller in shell.qml — no polling here.
// Shows media info from Mpris when no warning is active (event-driven, no poll).
// Width is set by anchors in shell.qml — do not set implicitWidth here.
// Shadow: offset y=5, blur 0.7, #00000077 — matches Niri window shadow config.

import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Effects

Item {
    id: root
    // width is set by anchors in shell.qml — do not set implicitWidth here
    implicitHeight: 24

    // Warning state bound from StatusPoller via shell.qml
    property string warningText:  ""
    property string warningClass: "none"

    // Computed display: warnings take priority over media
    readonly property string infoText: {
        if (warningClass === "warning") return warningText
        const players = Mpris.players.values
        if (players.length > 0) {
            const p = players[0]
            const icon = p.isPlaying ? "\uDB80\uDE08" : "\uDB82\uDDE4"   // 󰎈 / 󰏤
            return icon + " " + (p.trackArtist || "Unknown") + " - " + (p.trackTitle || "Unknown")
        }
        return ""
    }
    readonly property string infoClass: {
        if (warningClass === "warning") return "warning"
        if (Mpris.players.values.length > 0) return "media"
        return "none"
    }

    // ── Pill background (hidden — MultiEffect renders it with shadow) ─────────
    Rectangle {
        id: pillBg
        anchors.fill: parent
        color: root.infoClass === "warning" ? Colors.warningBg : Colors.pillBg
        bottomLeftRadius:  12
        bottomRightRadius: 12
        visible: false
        Behavior on color { ColorAnimation { duration: 300 } }
    }

    // Shadow + pill only shown when there is content to display
    MultiEffect {
        source:               pillBg
        anchors.fill:         pillBg
        visible:              root.infoClass !== "none"
        autoPaddingEnabled:   true
        shadowEnabled:        true
        shadowColor:          "#77000000"
        shadowBlur:           0.7
        shadowVerticalOffset: 5
        shadowHorizontalOffset: 0
    }

    Text {
        anchors.centerIn: parent
        width: parent.width - 24
        visible: root.infoClass !== "none"
        text:  root.infoText
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        font.family:    "FiraMono Nerd Font"
        font.pixelSize: 14
        color: "#fafafa"
    }
}
