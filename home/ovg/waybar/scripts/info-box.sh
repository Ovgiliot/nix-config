#!/usr/bin/env bash

# Function to get system warnings
get_warning() {
	# 1. Battery: Unplugged and below 20% (lowest battery, worst case)
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
	if [ "$ac_online" -eq 0 ]; then
		min_cap=100
		for psy in /sys/class/power_supply/*/; do
			type=$(cat "$psy/type" 2>/dev/null || true)
			[ "$type" = "Battery" ] || continue
			cap=$(cat "$psy/capacity" 2>/dev/null || true)
			[ -n "$cap" ] || continue
			[ "$cap" -lt "$min_cap" ] && min_cap=$cap
		done
		if [ "$min_cap" -lt 20 ] && [ "$min_cap" -ne 100 ]; then
			echo "󰂃 Low Battery: $min_cap%"
			return 0
		fi
	fi

	# 2. CPU Temperature: Above 95C
	max_temp=0
	for zone in /sys/class/thermal/thermal_zone*/temp; do
		if [ -f "$zone" ]; then
			t=$(cat "$zone")
			t=$((t / 1000))
			[ "$t" -gt "$max_temp" ] && max_temp=$t
		fi
	done
	if [ "$max_temp" -gt 95 ]; then
		echo " High Temp: ${max_temp}°C"
		return 0
	fi

	# 3. Disk Usage: Above 90%
	disk_usage=$(df / | awk 'NR==2 {print $5}' | tr -d '%')
	if [ "$disk_usage" -gt 90 ]; then
		echo "󰋊 Disk Full: $disk_usage%"
		return 0
	fi

	# 4. RAM Usage: Above 90%
	ram_usage=$(free | awk '/Mem:/ { printf("%.0f"), $3/$2 * 100 }')
	if [ "$ram_usage" -gt 90 ]; then
		echo "󰍛 High RAM: $ram_usage%"
		return 0
	fi

	# 5. CPU Usage: Above 90%
	# Using awk to sum /proc/stat fields accurately
	cpu_data=$(grep '^cpu ' /proc/stat)
	prev_total=$(echo "$cpu_data" | awk '{print $2+$3+$4+$5+$6+$7+$8+$9+$10+$11}')
	prev_idle=$(echo "$cpu_data" | awk '{print $5+$6}') # idle + iowait

	sleep 0.2

	cpu_data=$(grep '^cpu ' /proc/stat)
	total=$(echo "$cpu_data" | awk '{print $2+$3+$4+$5+$6+$7+$8+$9+$10+$11}')
	idle=$(echo "$cpu_data" | awk '{print $5+$6}')

	total_diff=$((total - prev_total))
	idle_diff=$((idle - prev_idle))

	if [ "$total_diff" -gt 0 ]; then
		cpu_usage=$((100 * (total_diff - idle_diff) / total_diff))
		if [ "$cpu_usage" -gt 90 ]; then
			echo "󰻠 High CPU: $cpu_usage%"
			return 0
		fi
	fi

	return 1
}

# Function to get media info
get_media_info() {
	player_status=$(playerctl status 2>/dev/null || true)
	if [ "$player_status" = "Playing" ] || [ "$player_status" = "Paused" ]; then
		artist=$(playerctl metadata artist 2>/dev/null || true)
		title=$(playerctl metadata title 2>/dev/null || true)
		icon="󰎈"
		[ "$player_status" = "Paused" ] && icon="󰏤"

		[ -z "$artist" ] && artist="Unknown"
		[ -z "$title" ] && title="Unknown"

		text="$icon $artist - $title"
		echo "{\"text\": \"$text\", \"class\": \"$player_status\", \"alt\": \"$player_status\"}"
	else
		echo "{\"text\": \"\", \"class\": \"none\"}"
	fi
}

# Main logic
if warning_msg=$(get_warning); then
	echo "{\"text\": \"$warning_msg\", \"class\": \"warning\", \"alt\": \"warning\"}"
else
	get_media_info
fi
