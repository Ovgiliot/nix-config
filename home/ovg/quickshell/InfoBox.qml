// Info-box widget.
// Polls warnings.sh every 30 s for system warnings (temp, disk, RAM, CPU).
// Shows media info from Mpris when no warning is active (event-driven, no poll).
// Click → play/pause via Mpris.
// Width is set by anchors in shell.qml — do not set implicitWidth here.
// Shadow: offset y=5, blur 0.7, #00000077 — matches Niri window shadow config.

import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick
import QtQuick.Effects

Item {
    id: root
    // width is set by anchors in shell.qml — do not set implicitWidth here
    implicitHeight: 24

    // Warning state from warnings.sh (30 s poll)
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

    readonly property color normalColor:  Qt.rgba(36/255, 41/255, 46/255, 0.55)
    readonly property color warningColor: Qt.rgba(248/255, 81/255, 73/255, 0.8)

    // ── Pill background (hidden — MultiEffect renders it with shadow) ─────────
    Rectangle {
        id: pillBg
        anchors.fill: parent
        color: root.infoClass === "warning" ? root.warningColor : root.normalColor
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
        font.family:    "JetBrainsMono Nerd Font"
        font.pixelSize: 14
        color: "#fafafa"
    }

    // Click → play/pause via Mpris (event-driven, no playerctl process)
    MouseArea {
        anchors.fill: parent
        onClicked: {
            const players = Mpris.players.values
            if (players.length > 0 && players[0].canTogglePlaying)
                players[0].togglePlaying()
        }
    }

    // ── Warnings poller (30 s; system checks only) ────────────────────────────
    Scripts { id: scripts }

    Process {
        id: warningsProc
        command: [scripts.warnings]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text.trim())
                    root.warningText  = d.text  || ""
                    root.warningClass = d.class || "none"
                } catch (_) {
                    root.warningClass = "none"
                }
            }
        }
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!warningsProc.running) warningsProc.running = true
    }
}
