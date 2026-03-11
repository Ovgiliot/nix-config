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

    // Parent PanelWindow — needed by PopupWindow for anchoring.
    property var parentWindow: null

    // BT state computed from Bluetooth singleton (event-driven)
    readonly property string btState: {
        const adapter = Bluetooth.defaultAdapter
        if (!adapter || !adapter.enabled) return "off"
        if (Bluetooth.devices.values.length > 0) return "connected"
        return "on"
    }

    // Laptop batteries from UPower — needed for per-battery popup rows.
    // Touch reactive properties inside the loop so QML tracks changes.
    readonly property var laptopBatteries: {
        const all = UPower.devices.values
        const result = []
        for (var i = 0; i < all.length; i++) {
            const dev = all[i]
            void dev.isLaptopBattery
            void dev.percentage
            void dev.state
            void dev.healthPercentage
            void dev.nativePath
            if (dev.isLaptopBattery) result.push(dev)
        }
        return result
    }
    readonly property bool hasBattery: laptopBatteries.length > 0

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

    function formatTime(seconds) {
        if (seconds <= 0) return "--:--"
        const h = Math.floor(seconds / 3600)
        const m = Math.floor((seconds % 3600) / 60)
        return h + ":" + (m < 10 ? "0" + m : m)
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
        // MouseArea triggers the battery detail popup on hover.
        MouseArea {
            id: batHover
            visible: root.hasBattery
            width: visible ? 80 : 0
            height: 16
            anchors.verticalCenter: parent.verticalCenter
            hoverEnabled: true

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

    // ── Battery detail popup — shown on hover over the battery bar ────────────
    // Positioned below the pill, right-aligned to its right edge, with 6px gap.
    // Lazily loaded to avoid crash: PopupWindow cannot resolve its anchor
    // during construction when the parent Item has no window yet.
    // relativeX/Y are relative to the parentWindow, so we map root's position.
    Loader {
        active: root.parentWindow !== null && root.hasBattery
        sourceComponent: PopupWindow {
            id: batPopup
            visible: batHover.containsMouse

            // Anchor to the bottom edge of the pill, left-aligned.
            // gravity: expand downward and rightward from the anchor point.
            // rect.y offset by 6 to create a 6px gap below the pill.
            anchor.item: root
            anchor.edges: Edges.Bottom | Edges.Left
            anchor.gravity: Edges.Bottom | Edges.Right
            anchor.rect.y: 6

            width:  root.width
            height: popupCol.implicitHeight + 16
            color:  "transparent"

            // Background (hidden — MultiEffect renders it with shadow)
            Rectangle {
                id: popupBg
                anchors.fill: parent
                color: Colors.pillBg
                radius: 8
                visible: false
            }

            MultiEffect {
                source:               popupBg
                anchors.fill:         popupBg
                autoPaddingEnabled:   true
                shadowEnabled:        true
                shadowColor:          Colors.shadowColor
                shadowBlur:           0.7
                shadowVerticalOffset: 5
                shadowHorizontalOffset: 0
            }

            Column {
                id: popupCol
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6

                // Time to full (on AC) or time to empty (on battery)
                Text {
                    text: root.batCharging
                        ? "Full in " + root.formatTime(UPower.displayDevice.timeToFull)
                        : root.formatTime(UPower.displayDevice.timeToEmpty) + " remaining"
                    font.family:    "FiraMono Nerd Font"
                    font.pixelSize: 13
                    color:          Colors.textColor
                }

                // Per-battery rows — bar stretches to fill between label and health text.
                Repeater {
                    model: root.laptopBatteries
                    Item {
                        required property var modelData
                        readonly property int level:  Math.round(modelData.percentage * 100)
                        readonly property int health: modelData.healthSupported
                                                    ? Math.round(modelData.healthPercentage)
                                                    : -1
                        width: popupCol.width
                        height: batLabel.height

                        Text {
                            id: batLabel
                            text: modelData.nativePath
                            font.family:    "FiraMono Nerd Font"
                            font.pixelSize: 13
                            color:          Colors.textColor
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            id: batHealth
                            text: health >= 0 ? "HP " + health + "%" : ""
                            font.family:    "FiraMono Nerd Font"
                            font.pixelSize: 13
                            color:          Colors.textColor
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Rectangle {
                            anchors.left: batLabel.right
                            anchors.leftMargin: 6
                            anchors.right: batHealth.left
                            anchors.rightMargin: health >= 0 ? 6 : 0
                            height: 10; radius: 5
                            anchors.verticalCenter: parent.verticalCenter
                            color: root.batTrackColor(level)
                            border.width: 1
                            border.color: Colors.outline

                            Rectangle {
                                width:  Math.max(0, (parent.width - 2) * level / 100)
                                height: parent.height - 2
                                x: parent.width - 1 - width
                                y: 1
                                radius: 4
                                color: root.batFillColor(level)
                            }
                        }
                    }
                }
            }
        }
    }
}
