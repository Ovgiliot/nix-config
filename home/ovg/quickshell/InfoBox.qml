// Info-box widget. Polls info-box.sh every 2 s.
// Width is determined by parent anchors (fills space between clock and right section).
// Shows system warnings at highest priority, then media info, then hides itself.
// Shadow: offset y=5, blur 0.7, #00000077 — matches Niri window shadow config.

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Effects

Item {
    id: root
    // width is set by anchors in shell.qml — do not set implicitWidth here
    implicitHeight: 24

    property string infoText:  ""
    property string infoClass: "none"

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

    // Click → play/pause
    MouseArea {
        anchors.fill: parent
        onClicked: Process.exec("playerctl", ["play-pause"])
    }

    // ── Script poller ─────────────────────────────────────────────────────────
    Process {
        id: infoProc
        command: ["/home/ovg/.config/waybar/scripts/info-box.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text.trim())
                    root.infoText  = d.text  || ""
                    root.infoClass = d.class || "none"
                } catch (_) {
                    root.infoClass = "none"
                }
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!infoProc.running) infoProc.running = true
    }
}
