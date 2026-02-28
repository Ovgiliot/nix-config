// Status icons widget: WiFi, Bluetooth, Power Profile, Battery.
// Polls status.sh every 5 s. Pill background driven by battery state.

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    implicitWidth:  iconsRow.implicitWidth + 16
    implicitHeight: 30

    property string wifiIcon:  "󰖪"
    property string btIcon:    "󰂲"
    property string powerIcon: ""
    property string batIcon:   ""
    property int    batLevel:  100
    property string batState:  "normal"   // "normal" | "charging" | "warning" | "critical"

    readonly property color normalColor:   Qt.rgba(80/255, 80/255,  90/255, 0.7)
    readonly property color warningColor:  Qt.rgba(210/255, 153/255, 34/255, 0.7)
    readonly property color criticalColor: Qt.rgba(248/255, 81/255,  73/255, 1.0)

    // Pill background — colour driven by battery state
    Rectangle {
        anchors.fill: parent
        color: {
            if (root.batState === "critical") return root.criticalColor
            if (root.batState === "warning")  return root.warningColor
            return root.normalColor
        }
        bottomLeftRadius:  12
        bottomRightRadius: 12
        Behavior on color { ColorAnimation { duration: 400 } }
    }

    // Action processes
    Process { id: wifiMenuProc; command: ["wifi-menu"] }
    Process { id: btMenuProc;   command: ["bluetooth-menu"] }
    Process { id: cyclePowerProc;
        command: ["/home/ovg/.config/waybar/scripts/cycle-power-profile.sh"] }

    // Icons row
    Row {
        id: iconsRow
        anchors.centerIn: parent
        spacing: 0

        // WiFi
        Text {
            width: 24
            horizontalAlignment: Text.AlignHCenter
            text:           root.wifiIcon
            font.family:    "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            color:          "#fafafa"
            MouseArea {
                anchors.fill: parent
                onClicked: wifiMenuProc.running = true
            }
        }

        // Bluetooth
        Text {
            width: 24
            horizontalAlignment: Text.AlignHCenter
            text:           root.btIcon
            font.family:    "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            color:          "#fafafa"
            MouseArea {
                anchors.fill: parent
                onClicked: btMenuProc.running = true
            }
        }

        // Power profile
        Text {
            width: 24
            horizontalAlignment: Text.AlignHCenter
            text:           root.powerIcon
            font.family:    "JetBrainsMono Nerd Font"
            font.pixelSize: 14
            color: {
                if (root.powerIcon === "") return "#ff7b72"   // performance
                if (root.powerIcon === "") return "#3fb950"   // power-saver
                return "#bc8cff"                               // balanced
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    cyclePowerProc.running = true
                    // Re-poll after a short delay to reflect the change
                    refreshTimer.restart()
                }
            }
        }

        // Battery
        Text {
            width: 36
            horizontalAlignment: Text.AlignHCenter
            text:           root.batIcon + " " + root.batLevel + "%"
            font.family:    "JetBrainsMono Nerd Font"
            font.pixelSize: 13
            color:          "#fafafa"
        }
    }

    // Script poller
    Process {
        id: statusProc
        command: ["/home/ovg/.config/waybar/scripts/status.sh"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text.trim())
                    root.wifiIcon  = d.wifi  || "󰖪"
                    root.btIcon    = d.bt    || "󰂲"
                    root.powerIcon = d.power || ""
                    root.batIcon   = d.bat_icon  || ""
                    root.batLevel  = d.bat_level ?? 100
                    root.batState  = d.bat_state || "normal"
                } catch (_) {}
            }
        }
    }

    Timer {
        id: pollTimer
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!statusProc.running) statusProc.running = true
    }

    // Quick re-poll after power profile cycle click
    Timer {
        id: refreshTimer
        interval: 800
        repeat: false
        onTriggered: if (!statusProc.running) statusProc.running = true
    }
}
