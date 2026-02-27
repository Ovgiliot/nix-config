#!/usr/bin/env bash
# Intelligent Power Profile Management
# Automatically switches between performance/balanced/power-saver profiles
# based on AC status and battery percentage.
# An override file in XDG_RUNTIME_DIR can pin a specific profile until "auto" is set.

# Find battery and AC devices
BAT=$(upower -e | grep -E 'battery_BAT[0-9]' | head -n 1)
AC=$(upower -e | grep -E 'line_power|AC|ADP' | head -n 1)

get_battery_percent() {
	if [ -n "$BAT" ]; then
		upower -i "$BAT" | grep 'percentage' | awk '{print $2}' | tr -d '%'
	fi
}

is_on_ac() {
	if [ -n "$AC" ]; then
		upower -i "$AC" | grep 'online' | awk '{print $2}'
	else
		echo "no"
	fi
}

set_profile() {
	new_profile="$1"
	current=$(powerprofilesctl get)
	if [ "$current" != "$new_profile" ]; then
		if powerprofilesctl set "$new_profile"; then
			notify-send -u normal "Power Profile" "Switched to $new_profile"
		fi
	fi
}

OVERRIDE_FILE="$XDG_RUNTIME_DIR/power_profile_override"

while true; do
	# Check for user overrides (written by power-menu via XDG_RUNTIME_DIR)
	if [ -f "$OVERRIDE_FILE" ]; then
		OVERRIDE=$(cat "$OVERRIDE_FILE")
		if [ "$OVERRIDE" = "auto" ]; then
			rm "$OVERRIDE_FILE"
		elif [ -n "$OVERRIDE" ]; then
			set_profile "$OVERRIDE"
			sleep 60
			continue
		fi
	fi

	AC_STATUS=$(is_on_ac)
	BAT_PERCENT=$(get_battery_percent)

	if [ "$AC_STATUS" = "yes" ]; then
		set_profile "performance"
	elif [ -n "$BAT_PERCENT" ]; then
		if [ "$BAT_PERCENT" -gt 40 ]; then
			set_profile "balanced"
		else
			set_profile "power-saver"
		fi
	else
		set_profile "balanced"
	fi

	sleep 60
done
