#!/usr/bin/env bash
# Outputs status bar data as JSON for Quickshell StatusIcons widget.
# Uses named state strings only — no unicode. Icons are mapped in QML.
# Fields: wifi (on|off|ethernet), bt (connected|on|off),
#         power (performance|balanced|power-saver),
#         batteries ([{level,state},...])
# Batteries discovered via sysfs type=Battery; empty array on desktop hosts.
# AC detection covers type=Mains (wired) and type=USB (USB-C PD).

# ── AC detection (Mains or USB-C PD) ─────────────────────────────────────────
ac_online=0
for psy in /sys/class/power_supply/*/; do
	type=$(cat "$psy/type" 2>/dev/null || true)
	if [ "$type" = "Mains" ] || [ "$type" = "USB" ]; then
		online=$(cat "$psy/online" 2>/dev/null || true)
		if [ "$online" = "1" ]; then
			ac_online=1
			break
		fi
	fi
done

# ── Batteries ─────────────────────────────────────────────────────────────────
bat_entries=""
for psy in /sys/class/power_supply/*/; do
	type=$(cat "$psy/type" 2>/dev/null || true)
	[ "$type" = "Battery" ] || continue

	level=$(cat "$psy/capacity" 2>/dev/null || true)
	[ -n "$level" ] || continue

	if [ "$ac_online" -eq 1 ]; then
		state="charging"
	elif [ "$level" -le 15 ]; then
		state="critical"
	elif [ "$level" -le 30 ]; then
		state="warning"
	else
		state="normal"
	fi

	entry="{\"level\":$level,\"state\":\"$state\"}"
	if [ -n "$bat_entries" ]; then
		bat_entries="$bat_entries,$entry"
	else
		bat_entries="$entry"
	fi
done

batteries_json="${bat_entries:+[$bat_entries]}"
batteries_json="${batteries_json:-[]}"

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

printf '{"wifi":"%s","bt":"%s","power":"%s","batteries":%s}\n' \
	"$wifi" "$bt" "$power" "$batteries_json"
