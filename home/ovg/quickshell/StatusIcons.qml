// Status icons widget: WiFi, Bluetooth, Power Profile, Battery.
// WiFi:    driven by WifiMonitor singleton in shell.qml (event-driven).
// Power:   driven by StatusPoller singleton in shell.qml (5 s poll).
// BT:      Quickshell.Bluetooth service singleton (event-driven).
// Battery: Quickshell.Services.UPower singleton (event-driven).
// Shadow: offset y=5, blur 0.7, #00000077 — matches Niri window shadow config.

import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Effects

Item {
    id: root
    implicitWidth:  iconsRow.implicitWidth + 36
    implicitHeight: 24

    // WiFi and power state bound from singletons via shell.qml
    property string wifiState:  "off"
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

    // state is one of: "performance", "balanced", "power-saver"
    function powerIcon(state) {
        if (state === "performance") return "\uDB85\uDC0B"   // U+F140B
        if (state === "power-saver") return "\uDB80\uDF2A"   // U+F032A  nf-md-leaf
        return "\uDB81\uDDD1"                                // U+F05D1  nf-md-scale_balance
    }

    function batIcon(level, charging) {
        if (charging)   return "\uDB80\uDC84"   // U+F0084  nf-md-battery_charging
        if (level > 80) return "\uDB80\uDC79"   // U+F0079  nf-md-battery
        if (level > 60) return "\uDB80\uDC80"   // U+F0080  nf-md-battery_70
        if (level > 40) return "\uDB80\uDC7E"   // U+F007E  nf-md-battery_50
        if (level > 20) return "\uDB80\uDC7B"   // U+F007B  nf-md-battery_20
        return "\uDB80\uDC8E"                   // U+F008E  nf-md-battery_outline
    }

    // ── Pill background (hidden — MultiEffect renders it with shadow) ─────────
    Rectangle {
        id: pillBg
        anchors.fill: parent
        color: Colors.pillBg
        bottomLeftRadius:  12
        bottomRightRadius: 12
        visible: false
    }

    MultiEffect {
        source:               pillBg
        anchors.fill:         pillBg
        autoPaddingEnabled:   true
        shadowEnabled:        true
        shadowColor:          Colors.shadowColor
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
            color:          Colors.textColor
        }

        // Bluetooth
        Text {
            width: 24
            horizontalAlignment: Text.AlignHCenter
            anchors.verticalCenter: parent.verticalCenter
            text:           root.btIcon(root.btState)
            font.family:    "FiraMono Nerd Font"
            font.pixelSize: 16
            color:          Colors.textColor
        }

        // Power profile
        Text {
            width: 24
            horizontalAlignment: Text.AlignHCenter
            anchors.verticalCenter: parent.verticalCenter
            text:           root.powerIcon(root.powerState)
            font.family:    "FiraMono Nerd Font"
            font.pixelSize: 16
            color:          Colors.textColor
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

                anchors.verticalCenter: parent.verticalCenter
                text:           root.batIcon(level, charging) + level + "%"
                font.family:    "FiraMono Nerd Font"
                font.pixelSize: 16
                color:          Colors.textColor
            }
        }
    }
}
