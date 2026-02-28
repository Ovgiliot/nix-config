// CPU + Memory widget.
// Polls cpu-mem.sh every 2 s; parses JSON {text, class, tooltip}.
// Pill background transitions smoothly between low/medium/high colours.

import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    implicitWidth: label.implicitWidth + 24
    implicitHeight: 30

    property string displayText: "  ░░░░░░░░ --%   ░░░░░░░░ --% "
    property color  pillColor:   Qt.rgba(63/255, 185/255, 80/255, 0.7)

    // Pill background
    Rectangle {
        anchors.fill: parent
        color: root.pillColor
        bottomLeftRadius:  12
        bottomRightRadius: 12
        Behavior on color { ColorAnimation { duration: 400 } }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.displayText
        font.family:    "JetBrainsMono Nerd Font"
        font.pixelSize: 12
        color: "#fafafa"
    }

    // Script poller
    Process {
        id: cpuMemProc
        command: ["/home/ovg/.config/waybar/scripts/cpu-mem.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text.trim())
                    root.displayText = d.text || root.displayText
                    if (d.class === "high")
                        root.pillColor = Qt.rgba(248/255, 81/255, 73/255, 0.7)
                    else if (d.class === "medium")
                        root.pillColor = Qt.rgba(210/255, 153/255, 34/255, 0.7)
                    else
                        root.pillColor = Qt.rgba(63/255, 185/255, 80/255, 0.7)
                } catch (_) {}
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!cpuMemProc.running) cpuMemProc.running = true
    }
}
