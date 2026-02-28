// Clock widget. Updates every minute via SystemClock.

import Quickshell
import QtQuick

Item {
    id: root
    implicitWidth:  timeText.implicitWidth + 24
    implicitHeight: 24

    // Pill background
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(36/255, 41/255, 46/255, 0.7)
        bottomLeftRadius:  12
        bottomRightRadius: 12
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
        font.family:    "JetBrainsMono Nerd Font"
        font.pixelSize: 16
        font.bold:      true
        color:          "#fafafa"
    }
}
