// Info-box widget. Polls info-box.sh every 2 s.
// Width is determined by parent anchors (fills space between clock and right section).
// Shows system warnings at highest priority, then media info, then hides itself.

import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    // width is set by anchors in shell.qml — do not set implicitWidth here
    implicitHeight: 24

    property string infoText:  ""
    property string infoClass: "none"

    readonly property color normalColor:  Qt.rgba(36/255, 41/255, 46/255, 0.55)
    readonly property color warningColor: Qt.rgba(248/255, 81/255, 73/255, 0.8)

    // Pill background — hidden when class is "none"
    Rectangle {
        anchors.fill: parent
        visible: root.infoClass !== "none"
        color: root.infoClass === "warning" ? root.warningColor : root.normalColor
        bottomLeftRadius:  12
        bottomRightRadius: 12
        Behavior on color { ColorAnimation { duration: 300 } }
    }

    Text {
        anchors.centerIn: parent
        width: parent.width - 24
        visible: root.infoClass !== "none"
        text:  root.infoText
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignHCenter
        font.family:    "JetBrainsMono Nerd Font"
        font.pixelSize: 16
        color: "#fafafa"
    }

    // Click → play/pause
    MouseArea {
        anchors.fill: parent
        onClicked: Process.exec("playerctl", ["play-pause"])
    }

    // Script poller
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
