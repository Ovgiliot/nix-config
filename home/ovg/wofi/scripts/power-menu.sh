#!/usr/bin/env bash

# Define options
OPTIONS="Auto
Performance
Balanced
Power Saver"

# Show menu
SELECTED=$(echo -e "$OPTIONS" | wofi --dmenu --prompt "Power Profile")

# Handle selection
# Write override to XDG_RUNTIME_DIR (user-private, unlike /tmp).
# The power-monitor service reads this file on every cycle.
case "$SELECTED" in
"Auto")
	echo "auto" >"$XDG_RUNTIME_DIR/power_profile_override"
	systemctl --user restart power-monitor
	;;
"Performance")
	echo "performance" >"$XDG_RUNTIME_DIR/power_profile_override"
	systemctl --user restart power-monitor
	;;
"Balanced")
	echo "balanced" >"$XDG_RUNTIME_DIR/power_profile_override"
	systemctl --user restart power-monitor
	;;
"Power Saver")
	echo "power-saver" >"$XDG_RUNTIME_DIR/power_profile_override"
	systemctl --user restart power-monitor
	;;
esac
