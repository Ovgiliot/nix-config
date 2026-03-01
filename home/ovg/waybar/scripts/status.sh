#!/usr/bin/env bash
# Outputs status bar data as JSON for Quickshell StatusIcons widget.
# Uses named state strings only — no unicode. Icons are mapped in QML.
# Fields: wifi (on|off|ethernet), bt (connected|on|off),
#         power (performance|balanced|power-saver),
#         bat_level (int), bat_state (normal|warning|critical|charging)

# ── Battery ───────────────────────────────────────────────────────────────────
bat_level=$(cat /sys/class/power_supply/BAT1/capacity 2>/dev/null || echo 100)
ac_online=$(cat /sys/class/power_supply/AC/online 2>/dev/null || echo 1)

# ── WiFi / Network ────────────────────────────────────────────────────────────
wifi_status=$(nmcli -t -f type,state dev 2>/dev/null || true)
if echo "$wifi_status" | grep -qE '^wifi:connected'; then
	wifi="on"
elif echo "$wifi_status" | grep -qE '^ethernet:connected'; then
	wifi="ethernet"
else
	wifi="off"
fi

# ── Bluetooth ─────────────────────────────────────────────────────────────────
bt_info=$(bluetoothctl show 2>/dev/null || true)
if echo "$bt_info" | grep -q 'Powered: yes'; then
	if bluetoothctl info 2>/dev/null | grep -q 'Connected: yes'; then
		bt="connected"
	else
		bt="on"
	fi
else
	bt="off"
fi

# ── Power profile ─────────────────────────────────────────────────────────────
power=$(powerprofilesctl get 2>/dev/null || echo "balanced")

# ── Battery state ─────────────────────────────────────────────────────────────
if [ "$ac_online" -eq 1 ]; then
	bat_state="charging"
elif [ "$bat_level" -le 15 ]; then
	bat_state="critical"
elif [ "$bat_level" -le 30 ]; then
	bat_state="warning"
else
	bat_state="normal"
fi

printf '{"wifi":"%s","bt":"%s","power":"%s","bat_level":%d,"bat_state":"%s"}\n' \
	"$wifi" "$bt" "$power" "$bat_level" "$bat_state"
