// Status icons widget: WiFi, Bluetooth, Power Profile, Battery.
// Polls status.sh every 5 s. Pill background driven by battery state.
// Icons mapped from named ASCII states; all glyphs live here in QML.

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    implicitWidth:  iconsRow.implicitWidth + 24
    implicitHeight: 24

    // Named states from status.sh
    property string wifiState:  "wifi_off"
    property string btState:    "bt_off"
    property string powerState: "balanced"
    property int    batLevel:   100
    property string batState:   "normal"   // "normal" | "charging" | "warning" | "critical"

    readonly property color normalColor:   Qt.rgba(36/255, 41/255, 46/255, 0.7)
    readonly property color warningColor:  Qt.rgba(210/255, 153/255, 34/255, 0.7)
    readonly property color criticalColor: Qt.rgba(248/255, 81/255,  73/255, 1.0)

    function wifiIcon(state) {
        if (state === "ethernet")  return "\uDB80\uDE00"   // U+F0200
        if (state === "wifi_on")   return "\uDB81\uDDA9"   // U+F05A9
        return "\uDB81\uDDAA"                              // U+F05AA  wifi_off
    }

    function btIcon(state) {
        if (state === "bt_connected") return "\uDB80\uDCB1"   // U+F00B1
        if (state === "bt_on")        return "\uDB80\uDCAF"   // U+F00AF
        return "\uDB80\uDCB2"                                 // U+F00B2  bt_off
    }

    function btColor(state) {
        if (state === "bt_connected") return "#fafafa"
        if (state === "bt_on")        return Qt.rgba(250/255, 250/255, 250/255, 0.7)
        return Qt.rgba(250/255, 250/255, 250/255, 0.4)
    }

    function powerIcon(state) {
        if (state === "performance") return "\uDB85\uDC0B"   // U+F140B
        if (state === "power-saver") return "\uDB81\uDCD8"   // U+F04D8
        return "\uDB81\uDCD2"                                // U+F04D2  balanced
    }

    function powerColor(state) {
        if (state === "performance") return "#ff7b72"
        if (state === "power-saver") return "#3fb950"
        return "#bc8cff"
    }

    function batIcon(level, state) {
        if (state === "charging") return "\uDB80\uDE04"   // U+F0204
        if (level > 87) return "\uf240"
        if (level > 62) return "\uf241"
        if (level > 37) return "\uf242"
        if (level > 12) return "\uf243"
        return "\uf244"
    }

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
    Process { id: wifiMenuProc;  command: ["wifi-menu"] }
    Process { id: btMenuProc;    command: ["bluetooth-menu"] }
    Process {
        id: cyclePowerProc
        command: ["/home/ovg/.config/waybar/scripts/cycle-power-profile.sh"]
    }

    // Icons row
    Row {
        id: iconsRow
        anchors.centerIn: parent
        spacing: 0

        // WiFi
        Text {
            width: 24
            horizontalAlignment: Text.AlignHCenter
            anchors.verticalCenter: parent.verticalCenter
            text:           root.wifiIcon(root.wifiState)
            font.family:    "JetBrainsMono Nerd Font"
            font.pixelSize: 16
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
            anchors.verticalCenter: parent.verticalCenter
            text:           root.btIcon(root.btState)
            font.family:    "JetBrainsMono Nerd Font"
            font.pixelSize: 16
            color:          root.btColor(root.btState)
            MouseArea {
                anchors.fill: parent
                onClicked: btMenuProc.running = true
            }
        }

        // Power profile
        Text {
            width: 24
            horizontalAlignment: Text.AlignHCenter
            anchors.verticalCenter: parent.verticalCenter
            text:           root.powerIcon(root.powerState)
            font.family:    "JetBrainsMono Nerd Font"
            font.pixelSize: 16
            color:          root.powerColor(root.powerState)
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    cyclePowerProc.running = true
                    refreshTimer.restart()
                }
            }
        }

        // Battery
        Text {
            horizontalAlignment: Text.AlignHCenter
            anchors.verticalCenter: parent.verticalCenter
            text:           root.batIcon(root.batLevel, root.batState) + " " + root.batLevel + "%"
            font.family:    "JetBrainsMono Nerd Font"
            font.pixelSize: 16
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
                    root.wifiState  = d.wifi       || "wifi_off"
                    root.btState    = d.bt         || "bt_off"
                    root.powerState = d.power      || "balanced"
                    root.batLevel   = d.bat_level  ?? 100
                    root.batState   = d.bat_state  || "normal"
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
