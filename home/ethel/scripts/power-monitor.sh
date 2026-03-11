#!/usr/bin/env bash
# Intelligent Power Profile Management
# Automatically switches between performance/balanced/power-saver profiles
# based on AC status and battery percentage.
# Supports multiple batteries (uses minimum level) and USB-C PD detection.
# An override file in XDG_RUNTIME_DIR can pin a specific profile until "auto" is set.

# Returns 0 if any AC source (Mains or USB-C PD) is online.
is_on_ac() {
	for psy in /sys/class/power_supply/*/; do
		type=$(cat "$psy/type" 2>/dev/null || true)
		if [ "$type" = "Mains" ] || [ "$type" = "USB" ]; then
			online=$(cat "$psy/online" 2>/dev/null || true)
			if [ "$online" = "1" ]; then
				return 0
			fi
		fi
	done
	return 1
}

# Prints the lowest capacity across all Battery-type supplies, or empty string.
min_battery_percent() {
	local min=101
	local found=0
	for psy in /sys/class/power_supply/*/; do
		type=$(cat "$psy/type" 2>/dev/null || true)
		[ "$type" = "Battery" ] || continue
		cap=$(cat "$psy/capacity" 2>/dev/null || true)
		[ -n "$cap" ] || continue
		found=1
		[ "$cap" -lt "$min" ] && min=$cap
	done
	[ "$found" -eq 1 ] && echo "$min"
}

set_profile() {
	new_profile="$1"
	current=$(powerprofilesctl get 2>/dev/null || true)
	if [ "$current" != "$new_profile" ]; then
		if powerprofilesctl set "$new_profile"; then
			notify-send -u normal "Power Profile" "Switched to $new_profile"
		fi
	fi
}

OVERRIDE_FILE="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/power_profile_override"

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

	if is_on_ac; then
		set_profile "performance"
	else
		BAT_PERCENT=$(min_battery_percent || true)
		if [ -n "$BAT_PERCENT" ]; then
			if [ "$BAT_PERCENT" -gt 40 ]; then
				set_profile "balanced"
			else
				set_profile "power-saver"
			fi
		else
			set_profile "balanced"
		fi
	fi

	sleep 60
done
