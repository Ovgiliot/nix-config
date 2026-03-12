#!/usr/bin/env bash

# Define options
OPTIONS="Auto
Performance
Balanced
Power Saver"

# Show menu — || true so dismissing the menu (exit 1) does not abort the script.
SELECTED=$(echo -e "$OPTIONS" | wofi --dmenu --prompt "Power Profile") || true

# Handle selection
# Write override to XDG_RUNTIME_DIR (user-private, unlike /tmp).
# The power-monitor service reads this file on every cycle.
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
case "$SELECTED" in
"Auto")
	echo "auto" >"$RUNTIME_DIR/power_profile_override"
	systemctl --user restart power-monitor
	;;
"Performance")
	echo "performance" >"$RUNTIME_DIR/power_profile_override"
	systemctl --user restart power-monitor
	;;
"Balanced")
	echo "balanced" >"$RUNTIME_DIR/power_profile_override"
	systemctl --user restart power-monitor
	;;
"Power Saver")
	echo "power-saver" >"$RUNTIME_DIR/power_profile_override"
	systemctl --user restart power-monitor
	;;
esac
