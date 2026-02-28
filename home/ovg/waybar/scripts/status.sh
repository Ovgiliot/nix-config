#!/usr/bin/env bash
# Outputs status bar data as JSON for Quickshell StatusIcons widget.
# Fields: wifi, bt, power, bat_icon, bat_level, bat_state

# ── Battery ──────────────────────────────────────────────────────────────────
bat_level=$(cat /sys/class/power_supply/BAT1/capacity 2>/dev/null || echo 100)
ac_online=$(cat /sys/class/power_supply/AC/online 2>/dev/null || echo 1)

# ── WiFi / Network ────────────────────────────────────────────────────────────
wifi_status=$(nmcli -t -f type,state dev 2>/dev/null)
if echo "$wifi_status" | grep -qE '^wifi:connected'; then
	wifi_icon=""
elif echo "$wifi_status" | grep -qE '^ethernet:connected'; then
	wifi_icon="󰈀"
else
	wifi_icon="󰖪"
fi

# ── Bluetooth ─────────────────────────────────────────────────────────────────
bt_info=$(bluetoothctl show 2>/dev/null)
if echo "$bt_info" | grep -q 'Powered: yes'; then
	if bluetoothctl info 2>/dev/null | grep -q 'Connected: yes'; then
		bt_icon=""
	else
		bt_icon=""
	fi
else
	bt_icon="󰂲"
fi

# ── Power profile ─────────────────────────────────────────────────────────────
power_profile=$(powerprofilesctl get 2>/dev/null || echo "balanced")
case "$power_profile" in
performance) power_icon="" ;;
power-saver) power_icon="" ;;
*) power_icon="" ;;
esac

# ── Battery icon + state ──────────────────────────────────────────────────────
if [ "$ac_online" -eq 1 ]; then
	bat_icon="󰂄"
	bat_state="charging"
elif [ "$bat_level" -le 15 ]; then
	bat_icon=""
	bat_state="critical"
elif [ "$bat_level" -le 30 ]; then
	bat_icon=""
	bat_state="warning"
elif [ "$bat_level" -le 50 ]; then
	bat_icon=""
	bat_state="normal"
elif [ "$bat_level" -le 75 ]; then
	bat_icon=""
	bat_state="normal"
else
	bat_icon=""
	bat_state="normal"
fi

printf '{"wifi":"%s","bt":"%s","power":"%s","bat_icon":"%s","bat_level":%d,"bat_state":"%s"}\n' \
	"$wifi_icon" "$bt_icon" "$power_icon" "$bat_icon" "$bat_level" "$bat_state"
