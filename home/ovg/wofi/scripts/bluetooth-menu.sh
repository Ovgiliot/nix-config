#!/usr/bin/env bash

if ! bluetoothctl show | grep -q "Powered: yes"; then
	action=$(echo -e "Power On\nExit" | wofi -dmenu -p "Bluetooth is Power Off" -i || true)
	if [ "$action" == "Power On" ]; then
		if bluetoothctl power on; then
			sleep 1
			exec "${BASH_SOURCE[0]}"
		else
			notify-send "Bluetooth" "Failed to power on — check rfkill or bluez status."
		fi
	else
		exit
	fi
fi

devices=$(bluetoothctl devices | cut -d ' ' -f 2- || true)
device_list=""
while read -r line; do
	[ -z "$line" ] && continue
	mac=$(echo "$line" | cut -d ' ' -f 1)
	name=$(echo "$line" | cut -d ' ' -f 2-)
	info=$(bluetoothctl info "$mac" || true)
	if echo "$info" | grep -q "Connected: yes"; then
		device_list+="CONNECTED: $name ($mac)\n"
	else
		device_list+="$name ($mac)\n"
	fi
done <<<"$devices"

device_list+="Scan for devices\nPower Off"

chosen=$(echo -e "$device_list" | wofi -dmenu -p "Bluetooth Devices" -i || true)

if [ -n "$chosen" ]; then
	if [ "$chosen" == "Scan for devices" ]; then
		notify-send "Bluetooth" "Scanning for 15 seconds..."
		bluetoothctl scan on &
		SCAN_PID=$!
		sleep 15
		bluetoothctl scan off || true
		kill "$SCAN_PID" 2>/dev/null || true
		exec "${BASH_SOURCE[0]}" # Re-run script
	elif [ "$chosen" == "Power Off" ]; then
		bluetoothctl power off || true
	else
		re='\(([^)]*)\)'
		[[ "$chosen" =~ $re ]] && mac="${BASH_REMATCH[1]}"
		if [[ "$chosen" == CONNECTED:* ]]; then
			bluetoothctl disconnect "$mac" || true
		else
			bluetoothctl connect "$mac" || (bluetoothctl pair "$mac" && bluetoothctl connect "$mac") || true
		fi
	fi
fi
