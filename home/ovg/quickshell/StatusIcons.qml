// Status icons widget: WiFi, Bluetooth, Power Profile, Battery.
// WiFi:    long-running wifi-monitor process (event-driven via nmcli monitor).
// BT:      Quickshell.Bluetooth service singleton (event-driven).
// Power:   shell-based poll via powerprofilesctl (5 s interval).
// Battery: Quickshell.Services.UPower singleton (event-driven).
// Pill background driven by worst laptop battery state.
// Shadow: offset y=5, blur 0.7, #00000077 — matches Niri window shadow config.

import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Effects

Item {
    id: root
    implicitWidth:  iconsRow.implicitWidth + 24
    implicitHeight: 24

    // WiFi state from long-running wifi-monitor process
    property string wifiState: "off"

    // Power profile state from periodic powerprofilesctl poll
    property string powerState: "balanced"

    // BT state computed from Bluetooth singleton (event-driven)
    readonly property string btState: {
        const adapter = Bluetooth.defaultAdapter
        if (!adapter || !adapter.enabled) return "off"
        if (Bluetooth.devices.values.length > 0) return "connected"
        return "on"
    }

    // Laptop batteries from UPower (filter by isLaptopBattery).
    // Touch dev.percentage and dev.state inside the loop so QML tracks
    // those property changes as reactive dependencies — otherwise the
    // binding only re-evaluates when devices are added/removed.
    readonly property var laptopBatteries: {
        const all = UPower.devices.values
        const result = []
        for (var i = 0; i < all.length; i++) {
            const dev = all[i]
            void dev.percentage
            void dev.state
            if (dev.isLaptopBattery) result.push(dev)
        }
        return result
    }

    // Worst battery state across all laptop batteries — drives pill color.
    // Priority: critical > warning > normal/charging.
    // FullyCharged is treated as charging so it never triggers a warning.
    readonly property string worstBatState: {
        var s = "normal"
        const bats = root.laptopBatteries
        for (var i = 0; i < bats.length; i++) {
            const b = bats[i]
            const lvl = Math.round(b.percentage * 100)
            const charging = b.state === UPowerDeviceState.Charging
                          || b.state === UPowerDeviceState.PendingCharge
                          || b.state === UPowerDeviceState.FullyCharged
            if (!charging && lvl <= 15) return "critical"
            if (!charging && lvl <= 30) s = "warning"
        }
        return s
    }

    readonly property color normalColor:   Qt.rgba(36/255, 41/255, 46/255, 0.8)
    readonly property color warningColor:  Qt.rgba(210/255, 153/255, 34/255, 0.8)
    readonly property color criticalColor: Qt.rgba(248/255, 81/255,  73/255, 1.0)

    function wifiIcon(state) {
        if (state === "ethernet") return "\uDB80\uDE00"   // U+F0200
        if (state === "on")       return "\uDB81\uDDA9"   // U+F05A9
        return "\uDB81\uDDAA"                             // U+F05AA  off
    }

    function btIcon(state) {
        if (state === "connected") return "\uDB80\uDCB1"   // U+F00B1
        if (state === "on")        return "\uDB80\uDCAF"   // U+F00AF
        return "\uDB80\uDCB2"                              // U+F00B2  off
    }

    function btColor(state) {
        if (state === "connected") return "#58a6ff"
        if (state === "on")        return Qt.rgba(250/255, 250/255, 250/255, 0.7)
        return Qt.rgba(250/255, 250/255, 250/255, 0.4)
    }

    // state is one of: "performance", "balanced", "power-saver"
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

    function batIcon(level, charging) {
        if (charging)   return "\uf1e6"   // U+F1E6  FA plug
        if (level > 87) return "\uf240"
        if (level > 62) return "\uf241"
        if (level > 37) return "\uf242"
        if (level > 12) return "\uf243"
        return "\uf244"
    }

    // ── Scripts path registry ─────────────────────────────────────────────────
    Scripts { id: scripts }

    // ── WiFi: long-running process — restart on exit so monitor stays live ────
    Process {
        running: true
        command: [scripts.wifiMonitor]
        onExited: running = true
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                const l = line.trim()
                if (!l) return
                try {
                    const d = JSON.parse(l)
                    root.wifiState = d.wifi || "off"
                } catch (_) {}
            }
        }
    }

    // ── Power profile: one-shot poll process ──────────────────────────────────
    property var _powerStateProc: Process {
        id: powerStateProc
        command: [scripts.getPower]
        stdout: SplitParser {
            splitMarker: "\n"
            onRead: (line) => {
                const l = line.trim()
                if (l) root.powerState = l
            }
        }
    }

    // Poll every 5 s; guard against overlapping runs.
    property var _powerPollTimer: Timer {
        interval: 5000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            if (!powerStateProc.running)
                powerStateProc.running = true
        }
    }

    // ── Pill background (hidden — MultiEffect renders it with shadow) ─────────
    Rectangle {
        id: pillBg
        anchors.fill: parent
        color: {
            if (root.worstBatState === "critical") return root.criticalColor
            if (root.worstBatState === "warning")  return root.warningColor
            return root.normalColor
        }
        bottomLeftRadius:  12
        bottomRightRadius: 12
        visible: false
        Behavior on color { ColorAnimation { duration: 400 } }
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

    // ── Icons row — 6px spacing for consistent visual separation ─────────────
    Row {
        id: iconsRow
        anchors.centerIn: parent
        spacing: 6

        // WiFi
        Text {
            width: 24
            horizontalAlignment: Text.AlignHCenter
            anchors.verticalCenter: parent.verticalCenter
            text:           root.wifiIcon(root.wifiState)
            font.family:    "FiraMono Nerd Font"
            font.pixelSize: 16
            color:          "#fafafa"
        }

        // Bluetooth
        Text {
            width: 24
            horizontalAlignment: Text.AlignHCenter
            anchors.verticalCenter: parent.verticalCenter
            text:           root.btIcon(root.btState)
            font.family:    "FiraMono Nerd Font"
            font.pixelSize: 16
            color:          root.btColor(root.btState)
        }

        // Power profile
        Text {
            width: 24
            horizontalAlignment: Text.AlignHCenter
            anchors.verticalCenter: parent.verticalCenter
            text:           root.powerIcon(root.powerState)
            font.family:    "FiraMono Nerd Font"
            font.pixelSize: 16
            color:          root.powerColor(root.powerState)
        }

        // Batteries — one entry per laptop battery; empty on desktop hosts
        Repeater {
            model: root.laptopBatteries
            Text {
                required property var modelData

                // FullyCharged treated as charging so icon/color stay correct
                readonly property bool charging: modelData.state === UPowerDeviceState.Charging
                                              || modelData.state === UPowerDeviceState.PendingCharge
                                              || modelData.state === UPowerDeviceState.FullyCharged
                // percentage is 0.0–1.0; multiply by 100 for display
                readonly property int  level:    Math.round(modelData.percentage * 100)

                width: 48
                horizontalAlignment: Text.AlignHCenter
                anchors.verticalCenter: parent.verticalCenter
                text:           root.batIcon(level, charging) + " " + level + "%"
                font.family:    "FiraMono Nerd Font"
                font.pixelSize: 16
                color:          "#fafafa"
            }
        }
    }
}
