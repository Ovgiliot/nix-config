#!/usr/bin/env bash

power_on=$(bluetoothctl show | grep "Powered: yes" | wc -l)
if [ "$power_on" -eq 0 ]; then
	action=$(echo -e "Power On\nExit" | wofi -dmenu -p "Bluetooth is Power Off" -i)
	if [ "$action" == "Power On" ]; then
		bluetoothctl power on
		sleep 1
		exec $0
	else
		exit
	fi
fi

devices=$(bluetoothctl devices | cut -d ' ' -f 2-)
device_list=""
while read -r line; do
	mac=$(echo "$line" | cut -d ' ' -f 1)
	name=$(echo "$line" | cut -d ' ' -f 2-)
	info=$(bluetoothctl info "$mac")
	connected=$(echo "$info" | grep "Connected: yes" | wc -l)
	if [ "$connected" -eq 1 ]; then
		device_list+="CONNECTED: $name ($mac)\n"
	else
		device_list+="$name ($mac)\n"
	fi
done <<<"$devices"

device_list+="Scan for devices\nPower Off"

chosen=$(echo -e "$device_list" | wofi -dmenu -p "Bluetooth Devices" -i)

if [ -n "$chosen" ]; then
	if [ "$chosen" == "Scan for devices" ]; then
		notify-send "Bluetooth" "Scanning for 15 seconds..."
		bluetoothctl scan on &
		SCAN_PID=$!
		sleep 15
		bluetoothctl scan off
		kill "$SCAN_PID" 2>/dev/null
		$0 # Re-run script
	elif [ "$chosen" == "Power Off" ]; then
		bluetoothctl power off
	else
		mac=$(echo "$chosen" | sed 's/.*(\([^)]*\)).*/\1/')
		if [[ "$chosen" == CONNECTED:* ]]; then
			bluetoothctl disconnect "$mac"
		else
			bluetoothctl connect "$mac" || (bluetoothctl pair "$mac" && bluetoothctl connect "$mac")
		fi
	fi
fi
