// Keyboard language widget. Polls language.sh every 1 s.
// Background transitions between gray (EN) and blue (RU).
// Text is bare "EN" / "RU" — no leading icon — ensuring clean centering.

import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root
    implicitWidth:  langLabel.implicitWidth + 24
    implicitHeight: 24

    property string langText:  "EN"
    property string langClass: "en"

    readonly property color enColor: Qt.rgba(36/255, 41/255, 46/255, 0.7)
    readonly property color ruColor: Qt.rgba(30/255, 100/255, 200/255, 0.7)

    // Pill background
    Rectangle {
        anchors.fill: parent
        color: root.langClass === "ru" ? root.ruColor : root.enColor
        bottomLeftRadius:  12
        bottomRightRadius: 12
        Behavior on color { ColorAnimation { duration: 300 } }
    }

    Text {
        id: langLabel
        anchors.centerIn: parent
        text:           root.langText
        font.family:    "JetBrainsMono Nerd Font"
        font.pixelSize: 16
        font.bold:      true
        color:          "#fafafa"
    }

    // Script poller
    Process {
        id: langProc
        command: ["/home/ovg/.config/waybar/scripts/language.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text.trim())
                    root.langText  = d.text  || "EN"
                    root.langClass = d.class || "en"
                } catch (_) {}
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!langProc.running) langProc.running = true
    }
}
