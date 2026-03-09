// Status icons widget: WiFi, Bluetooth, Power Profile, Battery.
// WiFi:    driven by WifiMonitor singleton in shell.qml (event-driven).
// Power:   driven by StatusPoller singleton in shell.qml (5 s poll).
// BT:      Quickshell.Bluetooth service singleton (event-driven).
// Battery: combined bar via UPower.displayDevice + UPower.onBattery (event-driven).
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

    // Whether any laptop battery exists — drives visibility of the bar.
    // Touch isLaptopBattery on each device so QML tracks add/remove reactively.
    readonly property bool hasBattery: {
        const all = UPower.devices.values
        for (var i = 0; i < all.length; i++) {
            void all[i].isLaptopBattery
            if (all[i].isLaptopBattery) return true
        }
        return false
    }

    // Combined level from UPower's virtual aggregate device (0–100).
    readonly property int batLevel: Math.round(UPower.displayDevice.percentage * 100)

    // Charger plugged in — UPower.onBattery is false when on AC power.
    // This correctly ignores internal battery-to-battery balancing.
    readonly property bool batCharging: !UPower.onBattery

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

    // Battery: lower = worse, so thresholds are inverted from CPU/MEM.
    function batFillColor(pct) {
        if (pct < 20) return Colors.errorFill
        if (pct < 40) return Colors.barFill
        return Colors.accent
    }
    function batTrackColor(pct) {
        if (pct < 20) return Colors.errorTrack
        if (pct < 40) return Colors.barTrack
        return Colors.primaryTrack
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

        // Battery bar — combined capacity; hidden on desktop (0 batteries).
        // Fill anchored right: full charge = full bar, depleted = shrinks from left.
        Item {
            visible: root.hasBattery
            width: visible ? 80 : 0
            height: 16
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                width: 80; height: 12; radius: 6
                anchors.verticalCenter: parent.verticalCenter
                color: root.batTrackColor(root.batLevel)
                border.width: 1
                border.color: root.batCharging ? Colors.barFill : Colors.outline
                Behavior on color { ColorAnimation { duration: 300 } }
                Behavior on border.color { ColorAnimation { duration: 300 } }

                Rectangle {
                    width:  Math.max(0, (parent.width - 2) * root.batLevel / 100)
                    height: parent.height - 2
                    x: parent.width - 1 - width
                    y: 1
                    radius: 5
                    color: root.batFillColor(root.batLevel)
                    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
            }
        }
    }
}
